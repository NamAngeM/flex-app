# Utiliser une image de base Ubuntu 22.04
FROM ubuntu:22.04

# Installer les dépendances nécessaires
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    libglu1-mesa \
    lib32stdc++6 \
    lib32z1 \
    openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/*

# Définir le bon JDK pour Gradle
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Définir les variables d'environnement pour le SDK Android
ENV ANDROID_HOME="/opt/android-sdk"
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${PATH}"

# Télécharger et installer Flutter 3.24.5
RUN git clone https://github.com/flutter/flutter.git -b stable /sdks/flutter \
    && cd /sdks/flutter && git checkout 3.24.5

# Ajouter Flutter au PATH
ENV PATH="/sdks/flutter/bin:$PATH"

# Télécharger et installer le SDK Android
RUN mkdir -p /opt/android-sdk/cmdline-tools \
    && curl -o sdk-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip \
    && unzip sdk-tools.zip -d /opt/android-sdk/cmdline-tools \
    && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
    && rm sdk-tools.zip

# Accepter les licences Android et installer les outils nécessaires
RUN yes | sdkmanager --licenses || true
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Vérifier l'installation de Flutter et du SDK
RUN flutter doctor

# Créer un utilisateur non-root pour exécuter Flutter
RUN useradd -m appuser
RUN chown -R appuser:appuser /sdks/flutter /opt/android-sdk
USER appuser

# Ajouter une exception pour le répertoire /sdks/flutter (évite des erreurs de permission)
RUN git config --global --add safe.directory /sdks/flutter

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers du projet
COPY --chown=appuser:appuser . .

# Installer les dépendances Flutter
RUN flutter pub get

# Construire l'APK en mode release
RUN flutter build apk --release

# Exposer les artefacts (optionnel)
CMD ["echo", "Build completed!"]
