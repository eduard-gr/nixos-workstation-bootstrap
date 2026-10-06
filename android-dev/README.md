# Android dev environment (Distrobox)

Android Studio, SDK, NDK, эмулятор и Gradle работают внутри Distrobox-контейнера
`android` на базе Ubuntu 24.04. Внутри — обычный FHS-Linux, поэтому скачанные
Studio бинарники (aapt2, toolchain NDK, эмулятор) запускаются как есть, без
`buildFHSEnv`, `nix-ld` и `patchelf`.

`$HOME` у контейнера общий с хостом: SDK (`~/Android/Sdk`), AVD
(`~/.android/avd`), кэш Gradle (`~/.gradle`), настройки Studio и сами проекты
лежат в домашнем каталоге и переживают пересоздание контейнера.

## Что внутри

| Файл | Назначение |
|---|---|
| `distrobox.ini` | Декларативное описание контейнера для `distrobox assemble` (образ + apt-пакеты) |
| `install-android-studio.sh` | Ставит/обновляет Studio в `~/.local/share/android-studio`, пишет `/etc/profile.d/android.sh`, экспортирует ярлык в меню KDE и `adb`/`fastboot` на хост |
| `../tools/android.nix` | Системная часть: `distrobox`, rootless podman, `~/.local/bin` в `PATH` |

Переменные внутри контейнера (`/etc/profile.d/android.sh`):

```
ANDROID_HOME      = $HOME/Android/Sdk
ANDROID_SDK_ROOT  = $HOME/Android/Sdk
ANDROID_USER_HOME = $HOME/.android
ANDROID_AVD_HOME  = $HOME/.android/avd
JAVA_HOME         = /usr/lib/jvm/java-17-openjdk-amd64
PATH             += ~/.local/share/android-studio/bin, $ANDROID_HOME/{emulator,platform-tools,cmdline-tools/latest/bin}
```

## Установка

После `nixos-rebuild switch` (модуль `tools/android.nix` подключён в обоих хостах):

### 1. Создать контейнер

```bash
distrobox assemble create --file /etc/nixos/android-dev/distrobox.ini
```

Первый раз скачивается образ Ubuntu и ставятся пакеты — несколько минут.

### 2. Поставить Android Studio

Запускать с хоста — скрипт сам перезапустится внутри контейнера:

```bash
/etc/nixos/android-dev/install-android-studio.sh
```

Не вызывайте его как `distrobox enter android -- /etc/nixos/...`: у контейнера
свой `/etc`, хостовый виден только как `/run/host/etc`, и путь не найдётся.

Скрипт берёт ссылку на последний tarball со страницы
developer.android.com/studio (имя файла `android-studio-<ver>-linux.tar.gz`,
где `<ver>` — номер версии в старых релизах или кодовое имя вроде `rabbit1` в
новых). Конкретную версию можно задать явно:

```bash
ANDROID_STUDIO_URL=https://edgedl.me.gvt1.com/android/studio/ide-zips/<ver>/android-studio-<name>-linux.tar.gz \
  /etc/nixos/android-dev/install-android-studio.sh
```

Тем же скриптом Studio обновляется (настройки и плагины лежат в
`~/.config/Google`, их он не трогает) — хотя встроенный апдейтер Studio тоже
работает, каталог установки принадлежит пользователю.

### 3. Первый запуск

Скрипт создаёт в контейнере команду `android-studio` — ссылку на запускатель
из `~/.local/share/android-studio/bin/` (в новых версиях это `studio`, в
старых `studio.sh`).

**Android Studio** появляется в меню KDE (ярлык запускает её в контейнере).
Из терминала:

```bash
distrobox enter android -- android-studio
# или: distrobox enter android, затем android-studio
```

В мастере первого запуска выберите **Custom** → SDK location: `~/Android/Sdk`.
Дальше SDK Manager работает как на обычном Linux.

### 4. adb / fastboot на хосте

После того как Studio установит SDK Platform-Tools, повторите шаг 2 — скрипт
экспортирует `adb` и `fastboot` из SDK в `~/.local/bin` (обёртки, вызывающие их
внутри контейнера). На хосте своего `adb` нет намеренно: один adb-сервер на
порту 5037 и одна версия — Studio и терминал хоста не перезапускают сервер друг
другу с ошибкой `adb server version doesn't match this client`.

USB-телефон виден без настроек: systemd ≥ 258 выдаёт uaccess на Android-устройства
сам, а `/dev` контейнер видит хостовый. `programs.adb.enable` и группа
`adbusers` в NixOS удалены и не нужны.

## Эмулятор

```bash
distrobox enter android
sdkmanager "system-images;android-35;google_apis;x86_64"
avdmanager create avd -n pixel8 -k "system-images;android-35;google_apis;x86_64"
emulator -avd pixel8
```

Нужен `/dev/kvm`: `tools/kvm.nix` + группа `kvm` у пользователя. Distrobox
сохраняет группы хоста внутри контейнера (`keep_original_groups`), так что
`ls -l /dev/kvm` и `id` внутри должны показать доступ.

Рендеринг идёт через Mesa контейнера на AMD iGPU. На **p15v** дискретная
NVIDIA в контейнере недоступна (`nvidia=false` в `distrobox.ini`: интеграция
distrobox ищет драйвер по FHS-путям и на NixOS его не находит), `nvidia-offload`
для эмулятора больше не работает. При проблемах с GPU:

```bash
emulator -avd pixel8 -gpu host                    # host GL через Mesa
emulator -avd pixel8 -gpu swiftshader_indirect    # программный fallback
```

## Сборка из CLI

```bash
distrobox enter android
cd ~/projects/my-android-app
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Настройка контейнера

Все изменения — в `distrobox.ini`, затем пересоздание (домашний каталог не
затрагивается, Studio и SDK остаются; шаг 2 нужно повторить ради
`/etc/profile.d` и ярлыка):

```bash
distrobox assemble create --replace --file /etc/nixos/android-dev/distrobox.ini
/etc/nixos/android-dev/install-android-studio.sh
```

**Другая JDK для Gradle.** Замените `openjdk-17-jdk-headless` на
`openjdk-21-jdk-headless` и путь `JAVA_HOME` в `install-android-studio.sh`.

**32-битные библиотеки** (старые build-tools, API < 24) — добавьте в
`distrobox.ini`:

```ini
init_hooks="dpkg --add-architecture i386 && apt-get update && apt-get install -y libc6:i386 libstdc++6:i386 zlib1g:i386"
```

**Разовая установка пакета** без пересоздания: `distrobox enter android -- sudo apt install <pkg>`
(пропадёт при `--replace` — для постоянного добавьте в `distrobox.ini`).

## Удаление

```bash
distrobox-export --app android-studio --delete    # внутри контейнера
distrobox rm android
rm -rf ~/.local/share/android-studio ~/.local/bin/{adb,fastboot}
# SDK и AVD: ~/Android ~/.android
```

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

**Эмулятор: `/dev/kvm permission denied`** — пользователь не в группе `kvm`
(после добавления нужен перелогин), проверьте `id` на хосте.

**adb не видит устройство** — на телефоне включите «Отладка по USB» и
подтвердите отпечаток ключа. `adb kill-server && adb devices` перечитает шину.
