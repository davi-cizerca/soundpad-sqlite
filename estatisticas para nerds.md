# Explicação para Nerds 🧠

## Visão Geral do Sistema de Banco de Dados

Este documento explica em detalhes técnicos como funciona o sistema de banco de dados e como os dados são persistidos no dispositivo.

## Arquitetura do Banco de Dados

### 1. Sistema de Persistência

O sistema utiliza **SQLite** como motor de banco de dados principal, escolhido por suas características:

- **Serverless**: Não requer processo servidor separado
- **Zero-configuration**: Funciona out-of-the-box
- **Single-file**: Todo o banco é armazenado em um único arquivo
- **ACID compliance**: Garante integridade transacional
- **Cross-platform**: Compatível com Windows, macOS e Linux

### 2. Estrutura de Arquivos

```
📁 Aplicação/
├── 📄 database.db          # Arquivo principal do SQLite
├── 📄 database.db-shm      # Shared memory (WAL mode)
├── 📄 database.db-wal      # Write-Ahead Log
└── 📁 backups/             # Diretório de backups automáticos
    ├── 📄 backup_2025-01-08.db
    └── 📄 backup_2025-04-08.db
```

### 3. Modo de Operação WAL (Write-Ahead Logging)

O sistema opera em modo **WAL** para otimizar performance:

- **Concurrent reads/writes**: Múltiplas operações simultâneas
- **Atomic commits**: Transações são atômicas e duráveis
- **Rollback capability**: Capacidade de desfazer operações
- **Performance**: Melhor throughput para aplicações com muitas escritas

## Esquema do Banco de Dados

### Tabelas Principais

#### Tabela: `sounds`
```sql
CREATE TABLE sounds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    duration REAL,
    sample_rate INTEGER,
    bit_depth INTEGER,
    channels INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_played TIMESTAMP,
    play_count INTEGER DEFAULT 0,
    tags TEXT,
    category TEXT,
    metadata TEXT  -- JSON com metadados adicionais
);
```

#### Tabela: `playlists`
```sql
CREATE TABLE playlists (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_favorite BOOLEAN DEFAULT 0,
    sort_order TEXT DEFAULT 'name'  -- 'name', 'date', 'custom'
);
```

#### Tabela: `playlist_sounds` (Relacionamento N:N)
```sql
CREATE TABLE playlist_sounds (
    playlist_id INTEGER,
    sound_id INTEGER,
    position INTEGER,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
    FOREIGN KEY (sound_id) REFERENCES sounds(id) ON DELETE CASCADE,
    PRIMARY KEY (playlist_id, sound_id)
);
```

#### Tabela: `settings`
```sql
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    type TEXT DEFAULT 'string',  -- 'string', 'integer', 'boolean', 'json'
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Mecanismos de Armazenamento

### 1. Estratégia de Persistência

#### Armazenamento de Arquivos de Áudio
- **Referência**: O banco armazena apenas **caminhos** para os arquivos
- **Localização**: Arquivos ficam em diretório dedicado (`/audio/`)
- **Integridade**: Verificação de existência de arquivos na inicialização
- **Backup**: Inclusão automática de arquivos de áudio nos backups

#### Metadados de Áudio
- **Extração**: Metadados são extraídos usando bibliotecas nativas (libsndfile, ffmpeg)
- **Cache**: Metadados são cacheados para evitar re-extração
- **Fallback**: Se extração falhar, usa valores padrão

### 2. Sistema de Backup

#### Backup Automático
```python
# Exemplo de estratégia de backup
def create_backup():
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    backup_path = f"backups/backup_{timestamp}.db"
    
    # Cria backup do banco
    shutil.copy2("database.db", backup_path)
    
    # Inclui arquivos de áudio
    audio_backup_dir = f"backups/audio_{timestamp}/"
    shutil.copytree("audio/", audio_backup_dir)
    
    # Limpa backups antigos (mantém últimos 7 dias)
    cleanup_old_backups(days=7)
```

#### Estratégia de Recuperação
- **Point-in-time recovery**: Restauração para momento específico
- **Incremental**: Apenas mudanças desde último backup
- **Verificação**: Checksum para validar integridade

### 3. Otimizações de Performance

#### Índices
```sql
-- Índices para consultas frequentes
CREATE INDEX idx_sounds_name ON sounds(name);
CREATE INDEX idx_sounds_category ON sounds(category);
CREATE INDEX idx_sounds_tags ON sounds(tags);
CREATE INDEX idx_sounds_created_at ON sounds(created_at);
CREATE INDEX idx_playlist_sounds_position ON playlist_sounds(playlist_id, position);
```

#### Prepared Statements
```python
# Uso de prepared statements para queries repetitivas
class SoundRepository:
    def __init__(self):
        self.find_by_name_stmt = self.db.prepare(
            "SELECT * FROM sounds WHERE name LIKE ?"
        )
    
    def find_by_name(self, name):
        return self.find_by_name_stmt.execute(f"%{name}%")
```

#### Connection Pooling
- **Reutilização**: Conexões são reutilizadas entre operações
- **Timeout**: Conexões inativas são fechadas automaticamente
- **Max connections**: Limite configurável de conexões simultâneas

## Tratamento de Erros e Recuperação

### 1. Validação de Dados

#### Constraints de Banco
```sql
-- Validações automáticas
CREATE TABLE sounds (
    -- ... outros campos ...
    file_size INTEGER CHECK (file_size > 0),
    duration REAL CHECK (duration > 0),
    sample_rate INTEGER CHECK (sample_rate IN (8000, 16000, 22050, 44100, 48000, 96000)),
    bit_depth INTEGER CHECK (bit_depth IN (8, 16, 24, 32))
);
```

#### Validação de Aplicação
```python
def validate_sound_file(file_path):
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Arquivo não encontrado: {file_path}")
    
    if not is_valid_audio_file(file_path):
        raise ValueError(f"Arquivo não é um áudio válido: {file_path}")
    
    return True
```

### 2. Tratamento de Falhas

#### Transações
```python
def add_sound_to_playlist(sound_id, playlist_id, position):
    try:
        with self.db.transaction():
            # Verifica se sound existe
            sound = self.get_sound(sound_id)
            if not sound:
                raise ValueError("Sound não encontrado")
            
            # Verifica se playlist existe
            playlist = self.get_playlist(playlist_id)
            if not playlist:
                raise ValueError("Playlist não encontrada")
            
            # Adiciona à playlist
            self.db.execute(
                "INSERT INTO playlist_sounds (playlist_id, sound_id, position) VALUES (?, ?, ?)",
                (playlist_id, sound_id, position)
            )
            
            # Reordena posições se necessário
            self.reorder_playlist_positions(playlist_id)
            
    except Exception as e:
        self.db.rollback()
        raise e
```

#### Rollback Automático
- **Transações aninhadas**: Suporte a transações dentro de transações
- **Savepoints**: Pontos de restauração intermediários
- **Logging**: Registro detalhado de todas as operações

## Monitoramento e Logging

### 1. Sistema de Logs

#### Logs de Operações
```python
import logging

class DatabaseLogger:
    def __init__(self):
        self.logger = logging.getLogger('database')
        self.logger.setLevel(logging.DEBUG)
        
        # Handler para arquivo
        file_handler = logging.FileHandler('database.log')
        file_handler.setLevel(logging.DEBUG)
        
        # Handler para console
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        
        # Formato
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        self.logger.addHandler(file_handler)
        self.logger.addHandler(console_handler)
```

#### Métricas de Performance
```python
class DatabaseMetrics:
    def __init__(self):
        self.query_times = []
        self.connection_count = 0
        self.transaction_count = 0
    
    def record_query_time(self, query, execution_time):
        self.query_times.append({
            'query': query,
            'time': execution_time,
            'timestamp': datetime.now()
        })
    
    def get_performance_stats(self):
        if not self.query_times:
            return {}
        
        times = [q['time'] for q in self.query_times]
        return {
            'total_queries': len(times),
            'avg_time': sum(times) / len(times),
            'min_time': min(times),
            'max_time': max(times),
            'slow_queries': len([t for t in times if t > 1.0])  # > 1 segundo
        }
```

### 2. Health Checks

#### Verificação de Integridade
```python
def check_database_health():
    health_status = {
        'database_file': check_file_exists('database.db'),
        'file_size': get_file_size('database.db'),
        'integrity': check_database_integrity(),
        'free_space': get_free_disk_space(),
        'last_backup': get_last_backup_time(),
        'connection_pool': get_connection_pool_status()
    }
    
    return health_status

def check_database_integrity():
    try:
        result = db.execute("PRAGMA integrity_check").fetchone()
        return result[0] == "ok"
    except Exception:
        return False
```

## Segurança e Privacidade

### 1. Sanitização de Inputs

#### Prepared Statements
- **SQL Injection**: Prevenção através de prepared statements
- **Input validation**: Validação rigorosa de todos os inputs
- **Type checking**: Verificação de tipos antes da inserção

#### Escape de Caracteres
```python
def sanitize_filename(filename):
    # Remove caracteres perigosos
    dangerous_chars = ['<', '>', ':', '"', '/', '\\', '|', '?', '*']
    for char in dangerous_chars:
        filename = filename.replace(char, '_')
    
    # Limita tamanho
    if len(filename) > 255:
        filename = filename[:255]
    
    return filename
```

### 2. Controle de Acesso

#### Permissões de Arquivo
- **Read-only**: Aplicação só lê arquivos de áudio
- **Write protection**: Proteção contra modificação acidental
- **Backup encryption**: Criptografia opcional para backups

## Considerações de Performance

### 1. Otimizações de Consulta

#### Query Optimization
```sql
-- Evita SELECT *
SELECT id, name, file_path, duration FROM sounds WHERE category = ?;

-- Usa LIMIT para grandes datasets
SELECT * FROM sounds ORDER BY created_at DESC LIMIT 100;

-- Paginação eficiente
SELECT * FROM sounds 
WHERE id > ? 
ORDER BY id 
LIMIT 50;
```

#### Lazy Loading
```python
class Sound:
    def __init__(self, sound_id):
        self.id = sound_id
        self._metadata = None
        self._waveform = None
    
    @property
    def metadata(self):
        if self._metadata is None:
            self._metadata = self.load_metadata()
        return self._metadata
    
    @property
    def waveform(self):
        if self._waveform is None:
            self._waveform = self.generate_waveform()
        return self._waveform
```

### 2. Cache Strategy

#### In-Memory Cache
```python
from functools import lru_cache

class SoundCache:
    def __init__(self, max_size=1000):
        self.cache = {}
        self.max_size = max_size
    
    @lru_cache(maxsize=100)
    def get_sound_metadata(self, sound_id):
        return self.load_metadata_from_db(sound_id)
    
    def invalidate_cache(self, sound_id):
        if sound_id in self.cache:
            del self.cache[sound_id]
```

## Conclusão

Este sistema de banco de dados foi projetado para ser:

- **Robusto**: Com tratamento de erros abrangente
- **Eficiente**: Otimizado para performance e uso de recursos
- **Escalável**: Capaz de crescer com o volume de dados
- **Manutenível**: Código limpo e bem documentado
- **Confiável**: Com sistema de backup e recuperação

Para mais detalhes técnicos, consulte a documentação da API ou entre em contato com a equipe de desenvolvimento.

---

*Última atualização: Agosto 2025*
*Versão do documento: 1.3*