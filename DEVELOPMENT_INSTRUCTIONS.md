# Instruções de Desenvolvimento - Umanni Fullstack Test

## Stack Tecnológica
- **Framework Backend**: Ruby on Rails (última versão estável - 8.1.1)
- **Ruby**: Versão 3.4.7
- **Banco de Dados**: PostgreSQL (recomendado para produção)
- **Frontend**: Hotwire (Turbo + Stimulus)
- **CSS**: SCSS
- **Framework CSS**: Bootstrap, Foundation, Material Design Lite ou similar
- **Real-time**: Action Cable (WebSockets)
- **Autenticação**: Devise ou similar (open source)
- **Upload de Arquivos**: Active Storage
- **Background Jobs**: Sidekiq (para importação de planilhas)

## Estrutura do Projeto

### 1. Configuração Inicial

#### 1.1 Criar o Projeto Rails
```bash
rails new umanni_user_management --database=postgresql --css=scss
```

#### 1.2 Gems Necessárias
Adicionar ao `Gemfile`:
- `devise` - Autenticação
- `pundit` ou `cancancan` - Autorização
- `roo` ou `spreadsheet_architect` - Processamento de planilhas
- `sidekiq` - Background jobs
- `redis` - Cache e Action Cable
- `rspec-rails` - Testes
- `factory_bot_rails` - Fixtures para testes
- `faker` - Dados fake para testes
- `simplecov` - Cobertura de testes (meta: 90%+)
- `rubocop` - Linter
- `brakeman` - Security scanner
- `bundler-audit` - Verificação de vulnerabilidades

#### 1.3 Configuração Docker
- Criar `Dockerfile` otimizado para produção
- Criar `docker-compose.yml` incluindo:
  - App Rails
  - PostgreSQL (senha: 123456)
  - Redis
  - Sidekiq

#### 1.4 Arquivos de Configuração
- `.gitignore` - Ignorar logs, tmp, node_modules, .env, etc
- `.dockerignore` - Otimizar build Docker
- `.rubocop.yml` - Configuração de linting
- `.rspec` - Configuração de testes
- `config/database.yml.example` - Template de configuração
- Usar variáveis de ambiente para configurações sensíveis

## 2. Modelagem de Dados

### 2.1 Model User
```ruby
# Atributos:
- full_name:string (presence: true, length: 2-100)
- email:string (presence: true, uniqueness: true, formato válido)
- avatar_image:attachment (Active Storage)
- role:enum (admin, user) - default: user
- timestamps

# Validações:
- Email único e formato válido
- Nome completo obrigatório
- Avatar opcional (validar tipo de arquivo e tamanho)
- Role deve ser admin ou user

# Métodos:
- admin? - verifica se é admin
- user? - verifica se é user normal
```

### 2.2 Model ImportJob (para rastrear imports)
```ruby
# Atributos:
- file_name:string
- status:enum (pending, processing, completed, failed)
- total_records:integer
- processed_records:integer
- failed_records:integer
- error_messages:text
- user_id:references (quem iniciou o import)
- timestamps

# Relacionamentos:
belongs_to :user
```

## 3. Funcionalidades por Perfil

### 3.1 Admin Dashboard
**Rota**: `/admin/dashboard`

**Componentes**:
- Total de usuários (contador em real-time via Action Cable)
- Total de usuários por role (gráfico/estatística em real-time)
- Lista de importações recentes com progresso
- Menu de navegação para CRUD de usuários

**Real-time**:
- Atualizar contadores quando novo usuário é criado/deletado
- Atualizar progresso de importação via WebSocket

### 3.2 CRUD de Usuários (Admin Only)
**Rotas**:
- `GET /admin/users` - Listar todos
- `GET /admin/users/new` - Formulário criar
- `POST /admin/users` - Criar
- `GET /admin/users/:id/edit` - Formulário editar
- `PATCH /admin/users/:id` - Atualizar
- `DELETE /admin/users/:id` - Deletar
- `PATCH /admin/users/:id/toggle_role` - Toggle role

**Funcionalidades**:
- Paginação (kaminari ou pagy)
- Busca/filtro por nome, email, role
- Upload de avatar (arquivo ou URL)
- Validação frontend e backend
- Confirmação antes de deletar

### 3.3 Importação de Planilha (Admin Only)
**Rota**: `POST /admin/users/import`

**Fluxo**:
1. Upload de arquivo CSV/XLSX
2. Validação inicial do arquivo
3. Criar ImportJob record
4. Enfileirar Sidekiq job
5. Processar em background
6. Broadcast progresso via Action Cable
7. Exibir barra de progresso na UI
8. Notificar conclusão/erros

**Validações**:
- Formato de arquivo (CSV, XLSX)
- Colunas obrigatórias: full_name, email, role
- Validar cada linha antes de importar
- Registrar erros por linha

### 3.4 User Profile
**Rota**: `/profile`

**Funcionalidades**:
- Visualizar próprios dados
- Editar full_name, email, avatar
- Deletar própria conta (com confirmação)
- Não pode alterar próprio role

### 3.5 Registro de Visitante
**Rota**: `GET /users/sign_up`

**Funcionalidades**:
- Formulário de registro público
- Criar user com role "user" por padrão
- Validação frontend e backend
- Confirmação de email (opcional mas recomendado)

## 4. Autenticação e Autorização

### 4.1 Devise Setup
- Rotas customizadas
- Views responsivas
- Redirecionamentos após login:
  - Admin → `/admin/dashboard`
  - User → `/profile`

### 4.2 Pundit Policies
```ruby
# UserPolicy
- index? - apenas admin
- create? - apenas admin
- update? - admin ou próprio usuário
- destroy? - admin ou próprio usuário (não pode deletar a si mesmo se for último admin)
- toggle_role? - apenas admin
- import? - apenas admin

# DashboardPolicy
- show? - apenas admin
```

## 5. Frontend

### 5.1 Layout Responsivo
- Framework CSS (Bootstrap 5 recomendado)
- Mobile-first
- Compatibilidade: Chrome, Firefox, Safari, Edge
- Navegação adaptativa (menu hamburguer mobile)

### 5.2 JavaScript
- Stimulus controllers para interatividade
- Turbo para navegação SPA-like
- Action Cable consumer para real-time
- Validação de formulários
- Preview de imagem antes de upload
- Confirmações de ações destrutivas

### 5.3 SCSS Organization
```
app/assets/stylesheets/
├── application.scss
├── variables.scss
├── mixins.scss
├── base/
│   ├── reset.scss
│   └── typography.scss
├── components/
│   ├── buttons.scss
│   ├── forms.scss
│   ├── cards.scss
│   └── navbar.scss
└── pages/
    ├── dashboard.scss
    ├── users.scss
    └── profile.scss
```

## 6. Testes

### 6.1 Estrutura de Testes
```
spec/
├── models/
│   ├── user_spec.rb
│   └── import_job_spec.rb
├── requests/
│   ├── admin/
│   │   ├── dashboard_spec.rb
│   │   └── users_spec.rb
│   └── profiles_spec.rb
├── services/
│   └── user_import_service_spec.rb
├── policies/
│   └── user_policy_spec.rb
├── factories/
│   ├── users.rb
│   └── import_jobs.rb
└── support/
    └── helpers.rb
```

### 6.2 Cobertura Mínima: 90%
- Models: validações, scopes, métodos
- Controllers/Requests: todas as rotas e cenários
- Services: lógica de negócio
- Policies: regras de autorização
- Jobs: processamento background

### 6.3 Tipos de Testes
- **Unit**: Models, Services, Policies
- **Integration**: Fluxos completos (registro → login → ações)
- **System**: Navegação e interação UI (Capybara)
- **Security**: SQL injection, XSS, CSRF (usar Brakeman)

### 6.4 Stress Tests (Extra Points)
- Apache Bench ou wrk
- Testar endpoints críticos:
  - Login
  - Listagem de usuários
  - Dashboard
  - Importação

## 7. Segurança

### 7.1 Proteções Obrigatórias
- ✅ CSRF protection (Rails padrão)
- ✅ SQL Injection (usar ActiveRecord corretamente)
- ✅ XSS (escapar output, sanitizar input)
- ✅ Mass Assignment (strong parameters)
- ✅ Autenticação segura (Devise)
- ✅ Autorização (Pundit)
- ✅ Upload seguro (validar tipo/tamanho de arquivo)
- ✅ Senhas hash (bcrypt via Devise)
- ✅ HTTPS em produção
- ✅ Headers de segurança (X-Frame-Options, CSP, etc)

### 7.2 Validações
- Sanitizar inputs
- Validar uploads (tipo MIME, extensão, tamanho)
- Rate limiting (Rack::Attack)
- Validação de email formato

## 8. Real-time Features

### 8.1 Action Cable Channels
```ruby
# DashboardChannel
- Broadcast quando user é criado/deletado
- Atualizar contadores em tempo real

# ImportProgressChannel
- Broadcast progresso de importação
- Atualizar barra de progresso
- Notificar conclusão
```

### 8.2 Stimulus Controller
```javascript
// dashboard_controller.js
- Subscribe to DashboardChannel
- Update counters on receive

// import_progress_controller.js
- Subscribe to ImportProgressChannel
- Update progress bar
- Show completion notification
```

## 9. Background Jobs

### 9.1 UserImportJob
```ruby
# Responsabilidades:
- Ler arquivo CSV/XLSX
- Validar cada linha
- Criar users válidos
- Registrar erros
- Atualizar ImportJob record
- Broadcast progresso via Action Cable

# Error Handling:
- Continuar processamento mesmo com erros
- Registrar linha e erro específico
- Não fazer rollback total
```

## 10. Otimizações

### 10.1 Performance
- Eager loading (N+1 queries)
- Paginação
- Cache de contadores
- Asset pipeline otimizado
- Lazy loading de imagens
- Redis para cache e jobs

### 10.2 SEO (Opcional)
- Meta tags apropriadas
- Sitemap
- robots.txt

## 11. Deploy e Infraestrutura

### 11.1 Docker
```dockerfile
# Multi-stage build
# Base image: ruby:3.3-alpine
# Instalar dependências do sistema
# Bundle install
# Precompilar assets
# Usuário não-root
# Health check
```

### 11.2 Docker Compose
```yaml
services:
  - web (Rails app)
  - db (PostgreSQL)
  - redis
  - sidekiq
volumes:
  - postgres_data
  - redis_data
```

### 11.3 Variáveis de Ambiente
- `DATABASE_URL` (PostgreSQL password: 123456)
- `POSTGRES_PASSWORD=123456`
- `REDIS_URL`
- `SECRET_KEY_BASE`
- `RAILS_ENV`
- Usar `dotenv-rails` em desenvolvimento

## 12. Documentação Final

### 12.1 README.md (em Inglês)
Deve incluir:
- Descrição do projeto
- Stack tecnológica
- Pré-requisitos (Docker, Docker Compose)
- Como buildar: `docker-compose build`
- Como rodar: `docker-compose up`
- Como rodar testes: `docker-compose run web rspec`
- Como acessar: `http://localhost:3000`
- Credenciais padrão (seed)
- Estrutura do projeto
- Decisões técnicas
- Comandos úteis

### 12.2 Seeds
Criar seed com:
- 1 usuário admin (admin@example.com / password)
- 10 usuários normais
- Dados realistas (Faker)

## 13. Checklist de Entrega

### Obrigatório
- [ ] README em inglês com instruções claras
- [ ] Framework CSS frontend (Bootstrap/Foundation/MDL)
- [ ] Real-time (contadores dashboard, progresso import)
- [ ] Tratamento de erros adequado
- [ ] Lib open source de autenticação (Devise)
- [ ] Git: commits semânticos, branch organizada
- [ ] SCSS para estilos
- [ ] `.gitignore` e `.dockerignore`
- [ ] Gerenciamento de configuração (ENV vars)
- [ ] Suporte multi-browser
- [ ] Código organizado e otimizado
- [ ] Validação frontend e backend
- [ ] Testes com 90%+ cobertura
- [ ] Dockerfile funcional
- [ ] docker-compose.yml

### Extra Points
- [ ] Docker multi-stage otimizado
- [ ] Stress tests documentados
- [ ] CI/CD pipeline (.github/workflows)
- [ ] Logs estruturados
- [ ] Monitoring/APM hooks

### Qualidade
- [ ] Código semântico, limpo e manutenível
- [ ] REST correto (GET, POST, PATCH, DELETE)
- [ ] Segurança (SQL injection, XSS, CSRF)
- [ ] Design patterns aplicados
- [ ] Linters configurados (Rubocop)
- [ ] Sem warnings de segurança (Brakeman)

## 14. Fluxo de Desenvolvimento

1. ✅ Setup inicial (Rails, Docker, gems)
2. ✅ Configurar Devise e User model
3. ✅ Implementar autorização (Pundit)
4. ✅ CRUD de usuários (admin)
5. ✅ Profile do usuário
6. ✅ Admin Dashboard com contadores
7. ✅ Action Cable para real-time
8. ✅ Importação de planilhas + Sidekiq
9. ✅ Frontend responsivo + validações
10. ✅ Testes (unit, integration, system)
11. ✅ Security audit (Brakeman, testes manuais)
12. ✅ Otimizações e polish
13. ✅ Documentação final
14. ✅ Code review e refactor
15. ✅ Deploy teste com Docker

## 15. Boas Práticas

### 15.1 Ruby/Rails
- Fat models, skinny controllers
- Service objects para lógica complexa
- Concerns para código compartilhado
- Decorators/Presenters para lógica de view
- Background jobs para operações longas
- Transações para operações críticas

### 15.2 Git
- Commits semânticos (feat:, fix:, refactor:, test:, docs:)
- Branch naming: feature/nome-feature
- Pull Request com descrição clara
- Code review checklist

### 15.3 Code Style
- Seguir Ruby Style Guide
- Rubocop sem offenses
- Comentários apenas quando necessário
- Nomes descritivos
- DRY (Don't Repeat Yourself)
- SOLID principles

## 16. Recursos Úteis

- Rails Guides: https://guides.rubyonrails.org/
- Devise: https://github.com/heartcombo/devise
- Pundit: https://github.com/varvet/pundit
- Hotwire: https://hotwired.dev/
- Bootstrap: https://getbootstrap.com/
- Sidekiq: https://github.com/sidekiq/sidekiq
- RSpec: https://rspec.info/
- SimpleCov: https://github.com/simplecov-ruby/simplecov
