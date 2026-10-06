# Android dev environment (Distrobox)

Android Studio, SDK, NDK, эмулятор и Gradle работают внутри Distrobox-контейнера
`android` на базе Ubuntu 24.04. Внутри — обычный FHS-Linux, поэтому скачанные
Studio бинарники (aapt2, toolchain NDK, эмулятор) запускаются как есть, без
`buildFHSEnv`, `nix-ld` и `patchelf`.

`$HOME` у контейнера общий с хостом: SDK (`~/Android/Sdk`), AVD
(`~/.android/avd`), кэш Gradle (`~/.gradle`), настройки Studio и сами проекты
лежат в домашнем каталоге и переживают пересоздание контейнера.

Документ состоит из трёх частей: [первый запуск](#первый-запуск) (один раз на
машину), [повседневная работа](#повседневная-работа) и
[обновление](#обновление). Дальше — справочник, удаление и диагностика.

---

## Первый запуск

Все команды выполняются на хосте в обычном терминале, если не сказано иначе.
На всё уходит 20–40 минут, большая часть — скачивание (образ Ubuntu, Studio
~1.3 ГБ, SDK и system image эмулятора ещё несколько ГБ).

### Шаг 0. Системная часть (NixOS)

Модуль `tools/android.nix` должен быть в `imports` хоста (в `l14` и `p15v`
он уже подключён). Для эмулятора нужен ещё `tools/kvm.nix` и группа `kvm` у
пользователя. Примените конфигурацию и проверьте:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#p15v    # или #l14
which distrobox podman                                # оба должны найтись
id | grep -o 'kvm'                                    # пользователь в группе kvm
ls -l /dev/kvm
```

Если группа `kvm` появилась только что — перелогиньтесь, иначе `id` её не
покажет и эмулятор не получит доступ к `/dev/kvm`.

`/etc/nixos` — отдельный клон этого репозитория. Если вы правили файлы в
рабочей копии, сначала сделайте push и `sudo git pull` в `/etc/nixos`: скрипт
ниже запускается именно оттуда.

### Шаг 1. Создать контейнер

```bash
distrobox assemble create --file /etc/nixos/android-dev/distrobox.ini
```

Скачивается образ Ubuntu 24.04 и ставятся apt-пакеты из `distrobox.ini`
(JDK 17, инструменты сборки, библиотеки для IDE и эмулятора) — несколько
минут. Проверка:

```bash
distrobox list                                        # android | Up ...
distrobox enter android -- java -version              # openjdk 17
```

### Шаг 2. Поставить Android Studio

Запускать **с хоста** — скрипт сам перезапустится внутри контейнера:

```bash
/etc/nixos/android-dev/install-android-studio.sh
```

Не вызывайте его как `distrobox enter android -- /etc/nixos/...`: у контейнера
свой `/etc`, хостовый виден только как `/run/host/etc`, и путь не найдётся.

Скрипт:

- скачивает последний tarball со страницы developer.android.com/studio и
  распаковывает его в `~/.local/share/android-studio`;
- пишет `/etc/profile.d/android.sh` (переменные `ANDROID_*`, `JAVA_HOME`,
  `PATH`, настройки Qt для эмулятора — см. [справочник](#переменные-окружения));
- создаёт в контейнере команду `android-studio` — обёртку, которая читает этот
  профиль и запускает Studio;
- экспортирует ярлык **Android Studio** в меню KDE;
- экспортирует `adb` и `fastboot` в `~/.local/bin` хоста, если SDK
  Platform-Tools уже установлены (при первом запуске их ещё нет — скрипт
  скажет `Skipping adb export`, это нормально, см. шаг 4).

Конкретную версию Studio можно задать явно:

```bash
ANDROID_STUDIO_URL=https://edgedl.me.gvt1.com/android/studio/ide-zips/<ver>/android-studio-<name>-linux.tar.gz \
  /etc/nixos/android-dev/install-android-studio.sh
```

Ярлык в меню появляется после перелогина или `kbuildsycoca6`.

### Шаг 3. Первый запуск Studio и установка SDK

Запустите Studio из меню KDE или из терминала:

```bash
distrobox enter android -- android-studio
```

В мастере первого запуска:

1. **Custom** setup.
2. **SDK location**: `/home/<user>/Android/Sdk` (значение по умолчанию
   подставится из `ANDROID_HOME`; проверьте, что это именно `~/Android/Sdk`, а
   не что-то под `~/.config`).
3. Оставьте включёнными **Android SDK**, **Android SDK Platform** и
   **Android Virtual Device**. Пункт **Performance (Android Emulator
   hypervisor driver)** можно снять: в Linux ускорение даёт KVM.
4. Дождитесь окончания загрузки компонентов.

После мастера откройте **More Actions → SDK Manager** и убедитесь, что
установлены **Android SDK Platform-Tools** (вкладка SDK Tools) и **Android
Emulator**. Проверка из терминала:

```bash
ls ~/Android/Sdk/platform-tools/adb ~/Android/Sdk/emulator/emulator
```

### Шаг 4. Экспортировать adb и fastboot на хост

Теперь, когда Platform-Tools установлены, повторите шаг 2:

```bash
/etc/nixos/android-dev/install-android-studio.sh
```

Скрипт переустановит Studio той же версии (это быстро, настройки не
трогаются) и положит в `~/.local/bin` обёртки `adb` и `fastboot`, которые
вызывают бинарники SDK внутри контейнера. Проверка с хоста:

```bash
adb version
```

На хосте своего `adb` нет намеренно: один adb-сервер на порту 5037 и одна
версия — Studio и терминал хоста не перезапускают сервер друг другу с ошибкой
`adb server version doesn't match this client`.

### Шаг 5. Создать и запустить эмулятор

Через Studio: **Device Manager → Create Virtual Device**, выберите модель и
system image (например Pixel 8, API 35, x86_64), нажмите ▶. Или из терминала
контейнера:

```bash
distrobox enter android
sdkmanager "system-images;android-35;google_apis;x86_64"
avdmanager create avd -n pixel8 -k "system-images;android-35;google_apis;x86_64"
emulator -avd pixel8
```

AVD должны лежать в `~/.android/avd` — тогда их видят и Studio, и терминал.
Проверка: `distrobox enter android -- emulator -list-avds`.

Рендеринг идёт через Mesa контейнера на AMD iGPU. На **p15v** дискретная
NVIDIA в контейнере недоступна (`nvidia=false` в `distrobox.ini`: интеграция
distrobox ищет драйвер по FHS-путям и на NixOS его не находит), `nvidia-offload`
для эмулятора не работает. При проблемах с GPU:

```bash
emulator -avd pixel8 -gpu host                    # host GL через Mesa
emulator -avd pixel8 -gpu swiftshader_indirect    # программный fallback
```

### Шаг 6. Подключить телефон (опционально)

На телефоне включите «Отладка по USB», подключите кабель и подтвердите
отпечаток ключа. На хосте:

```bash
adb devices
```

Никаких udev-правил и групп не нужно: systemd ≥ 258 выдаёт uaccess на
Android-устройства сам, а `/dev` контейнер видит хостовый.
`programs.adb.enable` и группа `adbusers` в NixOS удалены.

На этом первый запуск закончен.

---

## Повседневная работа

Контейнер стартует сам при первом обращении (`distrobox enter` или ярлык),
отдельно запускать его не нужно.

**Запустить Android Studio** — из меню KDE (**Android Studio**) или:

```bash
distrobox enter android -- android-studio
```

**Терминал внутри контейнера** (с `adb`, `emulator`, `sdkmanager`, `gradle`
и JDK в `PATH`):

```bash
distrobox enter android
```

Выход — `exit`. Домашний каталог тот же, что на хосте, так что проекты
открываются по тем же путям.

**adb/fastboot с хоста** работают из любого терминала без входа в контейнер:

```bash
adb devices
adb logcat
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

**Эмулятор без Studio**:

```bash
distrobox enter android -- emulator -avd pixel8
```

**Сборка из CLI**:

```bash
distrobox enter android
cd ~/projects/my-android-app
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

**Разовая установка apt-пакета** без пересоздания контейнера:

```bash
distrobox enter android -- sudo apt install <pkg>
```

Пакет пропадёт при пересоздании с `--replace`; для постоянного добавьте его в
`distrobox.ini` (см. [обновление](#обновление)).

---

## Обновление

**Android Studio.** Встроенный апдейтер Studio работает (каталог установки
принадлежит пользователю). Альтернатива — повторить шаг 2: скрипт скачает
текущий релиз и заменит `~/.local/share/android-studio`; настройки и плагины в
`~/.config/Google` и `~/.local/share/Google` не трогаются.

**Контейнер** (после правки `distrobox.ini`, обновления образа Ubuntu или если
в контейнере что-то сломалось). Домашний каталог не затрагивается, Studio, SDK
и AVD остаются; шаг 2 нужно повторить ради `/etc/profile.d/android.sh`,
обёртки `android-studio` и ярлыка:

```bash
distrobox assemble create --replace --file /etc/nixos/android-dev/distrobox.ini
/etc/nixos/android-dev/install-android-studio.sh
```

**Другая JDK для Gradle.** Замените `openjdk-17-jdk-headless` на
`openjdk-21-jdk-headless` в `distrobox.ini` и путь `JAVA_HOME` в
`install-android-studio.sh`, затем пересоздайте контейнер.

**32-битные библиотеки** (старые build-tools, API < 24) — добавьте в
`distrobox.ini` и пересоздайте контейнер:

```ini
init_hooks="dpkg --add-architecture i386 && apt-get update && apt-get install -y libc6:i386 libstdc++6:i386 zlib1g:i386"
```

**Скрипты в репозитории.** После изменения файлов в `android-dev/` сделайте
push и `sudo git pull` в `/etc/nixos`, иначе запустится старая версия.

---

## Справочник

### Файлы

| Файл | Назначение |
|---|---|
| `distrobox.ini` | Декларативное описание контейнера для `distrobox assemble` (образ + apt-пакеты) |
| `install-android-studio.sh` | Ставит/обновляет Studio в `~/.local/share/android-studio`, пишет `/etc/profile.d/android.sh`, создаёт обёртку `android-studio`, экспортирует ярлык в меню KDE и `adb`/`fastboot` на хост |
| `../tools/android.nix` | Системная часть: `distrobox`, rootless podman, `~/.local/bin` в `PATH` |

### Переменные окружения

Пишутся скриптом в `/etc/profile.d/android.sh` внутри контейнера:

```
ANDROID_HOME      = $HOME/Android/Sdk
ANDROID_SDK_ROOT  = $HOME/Android/Sdk
ANDROID_USER_HOME = $HOME/.android
ANDROID_AVD_HOME  = $HOME/.android/avd
JAVA_HOME         = /usr/lib/jvm/java-17-openjdk-amd64
PATH             += ~/.local/share/android-studio/bin, $ANDROID_HOME/{emulator,platform-tools,cmdline-tools/latest/bin}
_JAVA_AWT_WM_NONREPARENTING = 1
QT_QPA_PLATFORM   = xcb          (QT_PLUGIN_PATH и QT_WAYLAND_RECONNECT сбрасываются)
```

Строки Qt — для эмулятора: он несёт свой Qt только с xcb-плагином, а из
сессии KDE в контейнер протекают `QT_QPA_PLATFORM=wayland` и `QT_PLUGIN_PATH`
с Qt из `/nix/store`; с ними `qemu-system-x86_64` падает на старте.

### Команда `android-studio`

Обёртка `/usr/local/bin/android-studio` в контейнере читает
`/etc/profile.d/android.sh` и запускает
`~/.local/share/android-studio/bin/studio` (в старых версиях `studio.sh`).
Обёртка, а не симлинк, потому что ярлык из меню запускает её через non-login
shell, где `/etc/profile.d` не читается: без неё Studio не видит
`ANDROID_USER_HOME` (и складывает AVD в `~/.config/.android/avd`, невидимый из
терминала), а эмулятор получает хостовые Qt-переменные.

### Где что лежит

| Путь | Содержимое |
|---|---|
| `~/Android/Sdk` | SDK, platform-tools, emulator, system images |
| `~/.android/avd` | виртуальные устройства |
| `~/.android/debug.keystore` | ключ подписи debug-сборок |
| `~/.local/share/android-studio` | сама Studio |
| `~/.config/Google`, `~/.local/share/Google` | настройки и плагины Studio |
| `~/.gradle` | кэш Gradle |
| `~/.local/bin/{adb,fastboot}` | обёртки на хосте |

---

## Удаление

```bash
distrobox enter android -- distrobox-export --app android-studio --delete
distrobox rm android
rm -rf ~/.local/share/android-studio ~/.local/bin/{adb,fastboot}
# SDK, AVD и настройки Studio: ~/Android ~/.android ~/.config/Google ~/.local/share/Google ~/.gradle
```

---

## Диагностика

**`distrobox: command not found` / `podman` не найден** — модуль
`tools/android.nix` не подключён в `imports` хоста или не сделан `nixos-rebuild switch`.

**Ярлык в меню не появился** — перелогиньтесь или выполните `kbuildsycoca6`.

**`Could not find the Android Studio download URL`** — Google изменил формат
ссылки на странице загрузки. Возьмите ссылку на Linux-tarball со страницы
developer.android.com/studio вручную и передайте её через `ANDROID_STUDIO_URL`.

**Скрипт в `/etc/nixos` отличается от репозитория** — `/etc/nixos` это
отдельный клон того же GitHub-репозитория. После push из рабочей копии
выполните в нём `sudo git pull`, иначе запустится старая версия скрипта.

**Эмулятор падает сразу при старте** (coredump `qemu-system-x86`, в стеке
`QGuiApplicationPrivate::createPlatformIntegration` → `qAbort`, в выводе
`Available platform plugins are: offscreen, linuxfb, minimal, xcb, vnc`) —
Qt эмулятора не смог поднять платформенный плагин. Две причины: в контейнер
попали хостовые `QT_QPA_PLATFORM=wayland`/`QT_PLUGIN_PATH` (Studio запущена
старой ссылкой вместо обёртки — повторите шаг 2 и перезапустите Studio) или в
контейнере нет `libsm6`/`libice6` для xcb-плагина (контейнер собран по
старому `distrobox.ini` — пересоздайте с `--replace`). Проверка из контейнера:
`emulator -avd <имя> -no-snapshot-load`.

**Studio и терминал видят разные AVD** — Studio запускалась без
`ANDROID_USER_HOME` и создала их в `~/.config/.android/avd`. Перенесите
`<имя>.avd` и `<имя>.ini` в `~/.android/avd` и поправьте `path=` в ini (а
также скопируйте `~/.config/.android/debug.keystore` в `~/.android/`, чтобы
подпись debug-сборок не сменилась).

**Эмулятор: `/dev/kvm permission denied`** — пользователь не в группе `kvm`
(после добавления нужен перелогин), проверьте `id` на хосте.

**Эмулятор пишет `Switching to software rendering`** — Mesa в контейнере не
взяла iGPU, рендеринг идёт через lavapipe/swangle. Работает, но медленно;
попробуйте `-gpu host`.

**adb не видит устройство** — на телефоне включите «Отладка по USB» и
подтвердите отпечаток ключа. `adb kill-server && adb devices` перечитает шину.
