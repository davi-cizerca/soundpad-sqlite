# 🎵 SoundPad - Aplicativo de Gravação e Reprodução de Áudio

Um aplicativo Flutter moderno para gravação, reprodução e gerenciamento de áudios com interface intuitiva e funcionalidades avançadas.

## 📱 Funcionalidades

### ✨ Principais Recursos
- **Gravação de Áudio**: Grave áudios diretamente no dispositivo
- **Reprodução de Áudio**: Ouça áudios antes de salvar
- **Gerenciamento de Sons**: Organize seus áudios em botões personalizáveis
- **Interface Intuitiva**: Design moderno e fácil de usar
- **Cores Personalizáveis**: Escolha cores para cada botão de som
- **Histórico de Reprodução**: Acompanhe os sons mais tocados
- **Banco de Dados Local**: Armazenamento persistente com SQLite

### 🎯 Funcionalidades Específicas

#### 📹 Tela de Gravação
- Gravação de áudio em tempo real
- Controles de play/pause para ouvir gravações
- Indicadores visuais de status
- Gerenciamento automático de permissões
- Salvamento direto no SoundPad

#### 🎵 SoundPad Principal
- Grid de botões personalizáveis
- Reprodução com um toque
- Indicadores visuais de reprodução ativa
- Histórico de sons recentes
- Exclusão com toque longo
- Interface responsiva

#### ⚙️ Tela de Cadastro
- Prévia de áudio antes de salvar
- Seleção de arquivos de áudio
- Gravação integrada
- Personalização de cores
- Validação de dados

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework principal
- **SQLite**: Banco de dados local
- **AudioPlayers**: Reprodução de áudio
- **Flutter Sound**: Gravação de áudio
- **File Picker**: Seleção de arquivos
- **Permission Handler**: Gerenciamento de permissões
- **Path Provider**: Gerenciamento de arquivos

## 📋 Pré-requisitos

- Flutter SDK 3.7.0 ou superior
- Android SDK (API 24+)
- Permissões de gravação de áudio no dispositivo

## 🚀 Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/seu-usuario/soundpadsqlite.git
   cd soundpadsqlite
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Execute o aplicativo**
   ```bash
   flutter run
   ```

## 📱 Como Usar

### 🎙️ Gravação de Áudio
1. Acesse a aba "Gravar"
2. Conceda permissão de gravação quando solicitado
3. Toque em "Gravar" para iniciar
4. Toque em "Parar" para finalizar
5. Use "Ouvir" para escutar a gravação
6. Toque em "Salvar" para adicionar ao SoundPad

### 🎵 Usando o SoundPad
1. Na aba principal, toque em um botão para reproduzir
2. Toque no "+" para adicionar novos sons
3. Toque longo em um botão para excluir
4. Acesse o histórico através do ícone de relógio

### ⚙️ Adicionando Novos Sons
1. Toque no botão "+"
2. Digite um nome para o som
3. Selecione um arquivo de áudio ou grave um novo
4. Escolha uma cor para o botão
5. Ouça o áudio antes de salvar
6. Toque em "Salvar"

## 🔧 Configuração do Projeto

### Android
O projeto está configurado para Android com:
- MinSDK: 24
- NDK: 27.0.12077973
- Permissões de áudio configuradas

### Permissões Necessárias
- `RECORD_AUDIO`: Para gravação de áudio
- `READ_EXTERNAL_STORAGE`: Para acesso a arquivos
- `WRITE_EXTERNAL_STORAGE`: Para salvar gravações
- `READ_MEDIA_AUDIO`: Para Android 13+

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                 # Ponto de entrada do app
├── dao/                      # Camada de acesso a dados
│   ├── sound_button_dao.dart
│   └── dogdao.dart
├── database/                 # Configuração do banco
│   └── db.dart
├── model/                    # Modelos de dados
│   ├── model.dart
│   └── sound_button_model.dart
├── tela_cadastro_sound_button.dart    # Tela de cadastro
├── tela_gravacao_audio.dart           # Tela de gravação
├── tela_inicial_soundpad.dart         # Tela principal
├── tela_principal_com_abas.dart       # Navegação
└── permission_handler.dart            # Gerenciamento de permissões
```

## 🎨 Características da Interface

- **Design Material**: Interface moderna e intuitiva
- **Cores Dinâmicas**: Botões personalizáveis com cores
- **Feedback Visual**: Indicadores de status em tempo real
- **Responsividade**: Adaptável a diferentes tamanhos de tela
- **Acessibilidade**: Suporte a tooltips e navegação por toque

## 🔒 Gerenciamento de Permissões

O aplicativo gerencia automaticamente as permissões necessárias:
- Solicita permissão de gravação quando necessário
- Mostra diálogos explicativos
- Redireciona para configurações quando necessário
- Verifica status das permissões em tempo real

## 🐛 Solução de Problemas

### Problemas Comuns

1. **Erro de Permissão**
   - Vá em Configurações > Apps > SoundPad > Permissões
   - Habilite "Microfone" e "Armazenamento"

2. **Áudio não reproduz**
   - Verifique se o arquivo existe
   - Tente recarregar o aplicativo

3. **Gravação não funciona**
   - Verifique as permissões de microfone
   - Reinicie o aplicativo

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Desenvolvedor

**Davi Cizerça**
- Desenvolvido para a matéria de Desenvolvimento para Dispositivos Móveis
- Professor: Heitor Scalco Neto

## 📞 Suporte

Se você encontrar algum problema ou tiver sugestões, por favor:
1. Verifique se o problema já foi reportado
2. Crie uma nova issue com detalhes do problema
3. Inclua informações sobre seu dispositivo e versão do Android

---

⭐ **Se este projeto te ajudou, considere dar uma estrela!**
