# Niche AI Companion (MVP)

린 스타트업 검증을 위한 멘탈/습관 코칭 앱 "Niche AI Companion"입니다.
**Wizard of Oz** 기법을 통해 초기 사용자의 반응을 테스트하고, 데이터 기반으로 AI를 고도화할 수 있도록 설계되었습니다.

## 🚀 시작 가이드 (Execution Guide)

이 프로젝트를 실행하기 위해 필요한 단계입니다.

### 1. 필수 도구 설치
*   **Flutter SDK**: [설치 가이드](https://docs.flutter.dev/get-started/install/macos)를 참고하여 설치하세요.
*   **Firebase CLI**: 터미널에서 `npm install -g firebase-tools` 명령어로 설치합니다. (Node.js 필요)

### 2. 프로젝트 의존성 설치
터미널에서 프로젝트 폴더(`/Users/kimkyungho/MentalCoach`)로 이동 후 실행하세요:
```bash
flutter pub get
```

### 3. Firebase 설정 (필수!)
이 앱은 데이터 저장을 위해 Firebase를 사용하므로, 본인의 Firebase 프로젝트와 연결해야 합니다.

1.  **Firebase 로그인**:
    ```bash
    firebase login
    ```
2.  **프로젝트 설정**:
    - [Firebase 콘솔](https://console.firebase.google.com/)에서 새 프로젝트를 만듭니다.
    - 터미널에서 다음 명령어로 앱을 Firebase 프로젝트와 연결합니다:
      ```bash
      flutterfire configure
      ```
      *(만약 `flutterfire` 명령어가 없다면 `dart pub global activate flutterfire_cli` 로 설치하세요)*
    - **Firestore Database**와 **Authentication(Anonymous 로그인)**을 Firebase 콘솔에서 **활성화(Enable)** 해야 합니다.

### 4. 앱 실행
시뮬레이터나 연결된 기기에서 앱을 실행합니다.
```bash
flutter run
```

---

## 🧙‍♂️ Wizard of Oz 테스트 방법

창업자가 직접 AI인 척 연기하며 검증하는 방법입니다.

1.  **유저 모드 (앱 실행)**:
    - 앱을 실행하고 'Start Journey'를 눌러 온보딩을 완료합니다.
    - 채팅창에서 고민을 입력하거나 "I'm Overwhelmed" 버튼을 눌러봅니다.

2.  **관리자 모드 (앱 내 접속)**:
    - 앱 상단의 **'관리자 아이콘(방패 모양)'**을 클릭하거나, 코드에서 초기 경로를 `/admin`으로 변경하여 접속합니다.
    - **User List**에서 방금 가입한 유저를 선택합니다.
    - 유저가 보낸 메시지를 실시간으로 확인하고, **"Override AI Response"** 입력창을 통해 답변을 보냅니다.
    - 유저 화면에는 마치 AI가 답변한 것처럼 표시됩니다.

## 📂 폴더 구조
- `lib/main.dart`: 앱의 모든 UI 및 로직 (온보딩, 채팅, 관리자 패널)
- `assets/system_prompt.txt`: AI 페르소나 설계 (Fogg 행동 모델)
- `functions/index.js`: (옵션) 매일 알림을 보내는 자동화 서버 코드
