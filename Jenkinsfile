name: Android CI/CD

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'  # Version spécifique de Flutter
        channel: 'stable'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Analyze code
      run: flutter analyze
      
    - name: Run tests
      run: flutter test
      
    - name: Build APK
      run: flutter build apk --release --no-shrink
      
    - name: Upload APK artifact
      uses: actions/upload-artifact@v4
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
        if-no-files-found: error
