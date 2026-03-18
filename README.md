# Taxi Nearby

Um aplicativo Flutter para conectar passageiros a motoristas de táxi próximos em tempo real.

## 📋 Descrição

O Taxi Nearby é um aplicativo móvel desenvolvido em Flutter que permite aos usuários solicitar corridas de táxi de forma rápida e eficiente. O app conecta passageiros com motoristas disponíveis na área, oferecendo funcionalidades como rastreamento em tempo real, notificações, autenticação de usuários e suporte a voz para acessibilidade.

## ✨ Funcionalidades Principais

- **Autenticação de Usuários**: Login e registro para passageiros, motoristas e administradores
- **Rastreamento em Tempo Real**: Integração com Google Maps para localização e rotas
- **Solicitação de Corridas**: Interface intuitiva para passageiros solicitarem corridas
- **Notificações para Motoristas**: Sistema de notificações para alertar motoristas sobre novas solicitações
- **Suporte a Voz**: Funcionalidade de reconhecimento de voz para acessibilidade
- **Gerenciamento de Estado**: Utiliza Riverpod para gerenciamento eficiente do estado da aplicação
- **Temas**: Suporte a temas claro e escuro com modo automático do sistema

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework principal para desenvolvimento multiplataforma
- **Dart**: Linguagem de programação
- **Riverpod**: Gerenciamento de estado reativo
- **Google Maps Flutter**: Integração com mapas para localização e rotas
- **Geolocator**: Obtenção da localização do dispositivo
- **Speech to Text**: Reconhecimento de voz
- **Audioplayers**: Reprodução de áudio
- **Shared Preferences**: Armazenamento local de dados
- **Go Router**: Navegação declarativa
- **Google Fonts**: Tipografia personalizada

## 🚀 Como Executar

### Pré-requisitos

- Flutter SDK (versão 3.11.1 ou superior)
- Dart SDK
- Android Studio ou VS Code com extensões Flutter
- Dispositivo ou emulador Android/iOS

### Instalação

1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/taxi_nearby.git
   cd taxi_nearby
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Configure as chaves da API do Google Maps:
   - Adicione sua chave da API do Google Maps no arquivo `android/app/src/main/AndroidManifest.xml`
   - Para iOS, adicione no arquivo `ios/Runner/AppDelegate.swift`

4. Execute o aplicativo:
   ```bash
   flutter run
   ```

### Build para Produção

Para Android:
```bash
flutter build apk --release
```

Para iOS:
```bash
flutter build ios --release
```

## 📁 Estrutura do Projeto

```
lib/
├── core/                 # Configurações principais
│   ├── constants.dart    # Constantes da aplicação
│   ├── router.dart       # Configuração de rotas
│   └── theme.dart        # Temas da aplicação
├── models/               # Modelos de dados
│   ├── driver.dart       # Modelo do motorista
│   ├── ride_model.dart   # Modelo da corrida
│   └── user.dart         # Modelo do usuário
├── providers/            # Provedores Riverpod
│   └── auth_provider.dart # Provedor de autenticação
├── screens/              # Telas da aplicação
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── settings_screen.dart
│   ├── splash_screen.dart
│   ├── admin/            # Telas do administrador
│   ├── driver/           # Telas do motorista
│   └── passenger/        # Telas do passageiro
├── services/             # Serviços da aplicação
│   ├── auth_service.dart
│   ├── driver_notification_service.dart
│   ├── location_mock_service.dart
│   ├── location_simulation_service.dart
│   └── voice_service.dart
└── widgets/              # Widgets reutilizáveis
    ├── custom_button.dart
    └── taxi_marker.dart
```

## 🎯 Arquitetura

O aplicativo segue os princípios de Clean Architecture e utiliza:

- **MVVM Pattern**: Separação clara entre UI, lógica de negócio e dados
- **Provider Pattern**: Gerenciamento de estado com Riverpod
- **Service Layer**: Abstração de operações externas (API, localização, etc.)
- **Repository Pattern**: Acesso aos dados de forma consistente

## 📱 Plataformas Suportadas

- Android (API 21+)
- iOS
- Web (experimental)
- Windows, Linux, macOS (desktop)

## 🤝 Contribuição

Contribuições são bem-vindas! Para contribuir:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Contato

Para dúvidas ou sugestões, entre em contato através das issues do GitHub.

---

Desenvolvido com ❤️ usando Flutter
