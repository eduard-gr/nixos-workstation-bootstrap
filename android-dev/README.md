# Android dev environment (Nix flake + buildFHSEnv + direnv)

Переносимое окружение для разработки под Android на NixOS.

SDK, NDK, build-tools и образы эмулятора **не** декларируются в Nix — их
скачивает сама Android Studio в `$HOME/Android/Sdk`. `buildFHSEnv` создаёт
песочницу с настоящими `/lib64`, `/usr/lib` и `/etc`, поэтому скачанные
непропатченные бинарники (aapt2, toolchain NDK, эмулятор) находят
`/lib64/ld-linux-x86-64.so.2` и запускаются без `patchelf`.

## Что внутри

| Файл | Назначение |
|---|---|
| `flake.nix` | `pkgs.buildFHSEnv` → `devShells.x86_64-linux.default` |
| `.envrc` | `use flake` — автоматический вход в окружение при `cd` |

Переменные, которые выставляет `profile` FHS-окружения:

```
ANDROID_HOME      = $HOME/Android/Sdk
ANDROID_SDK_ROOT  = $HOME/Android/Sdk
ANDROID_USER_HOME = $HOME/.android
ANDROID_AVD_HOME  = $HOME/.android/avd
JAVA_HOME         = <jdk17 из nixpkgs>
GRADLE_USER_HOME  = $HOME/.gradle   (если не задана снаружи)
PATH             += $ANDROID_HOME/{emulator,platform-tools,cmdline-tools/latest/bin}
```

## Два нюанса, которые стоит знать

`pkgs.android-studio` в nixpkgs **уже** завёрнут в собственный FHS-враппер
(`android-studio-fhs-env`). Запуск из нашего окружения даёт вложенный bubblewrap
— проверено, работает. Но означает это следующее: libs, которые видит сам GUI
Studio, определяются врапером nixpkgs, а не нашим `targetPkgs`. Наше окружение
решает задачу для всего остального — Gradle, `aapt2`, toolchain NDK, `adb`,
эмулятор и всё, что запускается из терминала.

Скрипт `profile` при входе создаёт `$HOME/Android/Sdk` и `$HOME/.android/avd`,
если их нет. Это единственная запись за пределами стора, которую делает
окружение.

## Использование в новом проекте

### 1. Скопировать два файла в корень проекта

```bash
cd ~/projects/my-android-app
cp /etc/nixos/android-dev/flake.nix .
cp /etc/nixos/android-dev/.envrc .
```

В git-репозитории flake видит только файлы, известные git. Если проект уже под
git — добавьте их сразу, иначе `nix develop` скажет `path does not exist`:

```bash
git add flake.nix .envrc
```

### 2. Разрешить direnv

```bash
direnv allow
```

direnv блокирует `.envrc` до явного разрешения — это защита от выполнения
чужого кода при `cd` в скачанный репозиторий. Команду нужно повторять после
**каждого** изменения `.envrc` (при изменении `flake.nix` — не нужно,
nix-direnv пересоберёт окружение сам).

Первый вход займёт заметное время: качается Android Studio (~1.5 ГБ) и
зависимости FHS. Дальше вход мгновенный — `nix-direnv` кеширует окружение
в сторе и ставит GC-root, так что `nix-collect-garbage` его не удалит.

Проверка:

```bash
echo $ANDROID_HOME     # /home/eg/Android/Sdk
which adb emulator     # пути внутри $ANDROID_HOME
```

Без direnv то же самое даёт:

```bash
nix develop            # или: nix run .#android-sdk-env
```

### 3. Первый запуск Android Studio

```bash
android-studio
```

Запускать **только** изнутри окружения (из каталога проекта, после
`direnv allow`) — иначе Studio не увидит FHS-песочницу и скачанные ею
бинарники будут падать.

В мастере первого запуска выберите **Custom** → SDK location: `~/Android/Sdk`
(уже создан скриптом `profile`). Дальше SDK Manager работает как на обычном
Linux: ставьте любые platform/build-tools/NDK/system images — всё ложится в
`$HOME`, Nix в это не вмешивается.

### 4. Эмулятор

```bash
sdkmanager "system-images;android-35;google_apis;x86_64"
avdmanager create avd -n pixel8 -k "system-images;android-35;google_apis;x86_64"
emulator -avd pixel8
```

Нужен доступ к `/dev/kvm` — см. раздел «Требования к системе».

На **p15v** (гибридная графика Radeon 680M + RTX A2000) эмулятор по умолчанию
идёт на iGPU. Если рендеринг тормозит или ломается:

```bash
nvidia-offload emulator -avd pixel8      # на дискретной NVIDIA
emulator -avd pixel8 -gpu host           # явный выбор host GL
emulator -avd pixel8 -gpu swiftshader_indirect   # программный fallback
```

### 5. Сборка из CLI

```bash
./gradlew assembleDebug
adb devices
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Требования к системе

Всё перечисленное уже настроено в этом репозитории — список на случай
переноса на другую машину.

| Требование | Где включено |
|---|---|
| `/dev/kvm` для эмулятора | `tools/kvm.nix` + группа `kvm` в `users.users.eg.extraGroups` |
| direnv + nix-direnv | `tools/development.nix` → `programs.direnv` |
| adb/fastboot вне песочницы | `tools/development.nix` → `pkgs.android-tools` |
| nix-ld | `tools/development.nix` → `programs.nix-ld` |
| flakes | `nix.settings.experimental-features = [ "nix-command" "flakes" ]` в хост-конфиге |

### Про `programs.adb.enable` и группу `adbusers`

Их **не нужно** включать на этой системе, и `programs.adb.enable = true`
сломает сборку конфигурации:

```
The option `programs.adb' no longer exists.
This option is no longer needed as systemd 258 handles uaccess rules
automatically. Please add `pkgs.android-tools` to your system packages
to get the adb command.
```

Пакет `pkgs.android-udev-rules` удалён из nixpkgs по той же причине. Система
на systemd 261, uaccess-правила для Android-устройств встроены — телефон по
USB виден обычному пользователю без групп и udev-правил. Группы `adbusers`
больше не существует.

На системах с systemd < 258 (старые релизы NixOS) старый рецепт всё ещё
актуален:

```nix
programs.adb.enable = true;
users.users.<user>.extraGroups = [ "adbusers" "kvm" ];
```

## Настройка окружения под проект

**Другая версия JDK.** В `flake.nix` замените `jdk17` в `targetPkgs` и в
`JAVA_HOME`:

```nix
jdk21
...
export JAVA_HOME="${pkgs.jdk21.home}"
```

**32-битные библиотеки.** Старые build-tools (API < 24) содержат 32-битные
бинарники. Добавьте в `buildFHSEnv`:

```nix
multiPkgs = pkgs: with pkgs; [ zlib ncurses5 stdenv.cc.cc.lib ];
```

Это заметно удлиняет первую сборку — включайте только при реальной нужде.

**Своя библиотека для нативного кода.** Добавьте пакет в `targetPkgs` и
перезайдите в каталог (`direnv reload`).

**Зафиксировать nixpkgs.** У проекта свой `flake.lock`, независимый от
системного:

```bash
nix flake update        # поднять nixpkgs
nix flake metadata      # посмотреть текущую ревизию
```

Коммитьте `flake.lock` в репозиторий проекта — это и есть воспроизводимость.

## Диагностика

**`direnv: error .envrc is blocked`** — выполните `direnv allow`.

**`direnv` молчит при `cd`** — хук не подключён к оболочке. `programs.direnv`
добавляет его для bash/zsh/fish автоматически; после включения опции нужен
`nixos-rebuild switch` и новый сеанс оболочки.

**`error: path '/nix/store/...-source/flake.nix' does not exist`** — проект под
git, а `flake.nix` не добавлен в индекс: `git add flake.nix .envrc`.

**Studio не видит SDK** — запущена системная копия вместо той, что внутри
песочницы. Проверьте `echo $IN_NIX_SHELL` и `which android-studio` — путь
должен вести в стор FHS-окружения.

**`CANNOT LINK EXECUTABLE ... ld-linux-x86-64.so.2`** — команда выполняется вне
песочницы. Войдите в каталог проекта (direnv) или используйте `nix develop`.

**adb не видит устройство** — на телефоне включите «Отладка по USB» и
подтвердите отпечаток ключа. `adb kill-server && adb devices` перечитает шину.
