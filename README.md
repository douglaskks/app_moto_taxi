# MotoApp - Aplicativo de Mototáxi

## 📱 Visão Geral

MotoApp é um aplicativo inovador de mototáxi desenvolvido em Flutter, oferecendo uma solução completa para mobilidade urbana através de serviços de mototáxi. O aplicativo conecta passageiros a motoristas de forma eficiente, segura e conveniente.

## 🚀 Funcionalidades Principais

### Para Passageiros
- 📍 Localização precisa em tempo real
- 🏍️ Solicitação rápida de corridas
- 💬 Chat em tempo real com motoristas
- 💳 Múltiplas opções de pagamento
- 📊 Histórico de corridas
- ⭐ Avaliação de motoristas

### Para Motoristas
- 🌐 Modo online/offline
- 📍 Rastreamento de localização
- 💰 Acompanhamento de ganhos
- 📱 Aceite e rejeição de corridas
- 📊 Painel de desempenho

## 🛠 Tecnologias Utilizadas

- **Framework**: Flutter
- **Linguagem**: Dart
- **Gerenciamento de Estado**: Flutter Bloc
- **Banco de Dados**: Firebase Realtime Database
- **Autenticação**: Firebase Authentication
- **Mapas**: Google Maps Flutter

## 📦 Dependências Principais

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.0
  firebase_database: ^10.2.0
  google_maps_flutter: ^2.3.0
  bloc: ^8.1.2
```

## 🔧 Configuração do Projeto

### Pré-requisitos
- Flutter SDK (versão 3.10 ou superior)
- Dart SDK
- Android Studio ou VS Code
- Conta no Firebase

### Instalação

1. Clone o repositório
```bash
git clone https://github.com/douglaskks/app_moto_taxi.git
cd app_moto_taxi
```

2. Instale as dependências
```bash
flutter pub get
```

3. Configuração do Firebase
- Crie um novo projeto no Firebase Console
- Adicione um novo aplicativo Android/iOS
- Faça o download do `google-services.json` 
- Coloque o arquivo na pasta `android/app/`

4. Execute o aplicativo
```bash
flutter run
```

## 🔐 Configuração de Ambiente

### Variáveis de Ambiente
Crie um arquivo `.env` na raiz do projeto com as seguintes configurações:

```
FIREBASE_API_KEY=sua_chave_aqui
FIREBASE_APP_ID=seu_app_id
FIREBASE_MESSAGING_SENDER_ID=seu_sender_id
FIREBASE_PROJECT_ID=seu_project_id
```

## 🧪 Testes

### Executar Testes Unitários
```bash
flutter test
```

### Executar Testes de Widget
```bash
flutter test test/widget_test.dart
```

## 🌐 Arquitetura

### Estrutura de Pastas
```
lib/
├── controllers/
│   └── bloc/           # Lógica de negócio com Bloc
├── core/
│   ├── constants/      # Constantes globais
│   └── services/       # Serviços da aplicação
├── models/             # Modelos de dados
└── views/              # Interfaces de usuário
```

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie sua feature branch (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

## 📋 Roadmap

- [ ] Implementar sistema de pagamento completo
- [ ] Desenvolver painel administrativo
- [ ] Adicionar suporte a múltiplos idiomas
- [ ] Implementar testes de integração

## 🔒 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para detalhes.

## 📞 Contato

Douglas - [Seu LinkedIn/GitHub]

Link do Projeto: [https://github.com/douglaskks/app_moto_taxi](https://github.com/douglaskks/app_moto_taxi)

## 🙏 Agradecimentos

- Flutter Team
- Firebase
- Comunidade Open Source
```