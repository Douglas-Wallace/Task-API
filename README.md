# TaskAPI — Tarefa Prática 03 (Sessões e Service Layer)

## Versões

| Item | Versão |
|---|---|
| Java | 17+ |
| Apache Tomcat | 11.0.4 (Jakarta Servlet 6.1) |
| MySQL Connector/J | 9.1.0 |
| Gson | 2.11.0 |

Os `.jar` ficam em `src/main/webapp/WEB-INF/lib` e não são versionados.

## Banco

- Banco novo: `schema.sql`
- Banco da Tarefa 02: `migracao-03.sql`

No MySQL Workbench, a migração esbarra no *safe update mode* (erro 1175). Rode antes `SET SQL_SAFE_UPDATES = 0;` na mesma aba.

A conexão lê `TASKDB_URL`, `TASKDB_USER` e `TASKDB_PASS` (variável de ambiente ou `-D`). Padrão: `jdbc:mysql://localhost:3306/taskdb`, `root`, senha vazia.

### Usuários de teste

| Usuário | E-mail | Senha |
|---|---|---|
| A | `ana@taskapi.test` | `ana123` |
| B | `bruno@taskapi.test` | `bruno123` |

As senhas ficam no banco como hash PBKDF2-SHA256 com salt.

## Importador

Compile e rode fora do Tomcat (no Windows o separador de classpath é `;`):

```bash
javac -d out -cp "<tomcat>/lib/servlet-api.jar;src/main/webapp/WEB-INF/lib/gson-2.11.0.jar" $(find src/main/java -name "*.java")
```

```bash
java -cp "out;src/main/webapp/WEB-INF/lib/mysql-connector-j-9.1.0.jar" br.edu.ifsp.web.cli.ImportadorConclusoes ids.txt ana@taskapi.test ana123
```

O arquivo tem um id por linha. Cada linha imprime `concluida`, `nao encontrada` ou `ja estava concluida`. Credenciais inválidas encerram com código 1.

## Roteiro de verificação (item 09)

O contexto da aplicação é `/aula-taskapi` (nome do projeto no Eclipse).

```bash
B=http://localhost:8080/aula-taskapi
curl -i $B/tarefas
curl -i -c c.txt -b c.txt -H "Content-Type: application/json" -d '{"email":"ana@taskapi.test","senha":"errada"}' $B/auth/login
curl -i -c c.txt -b c.txt -H "Content-Type: application/json" -d '{"email":"ana@taskapi.test","senha":"ana123"}' $B/auth/login
curl -i -b c.txt $B/tarefas
```

| Etapa | Esperado | Obtido |
|---|---|---|
| 1 | 401 com JSON | |
| 2 | 401 | |
| 3 | 200, sem credencial, sessão nova | |
| 4 | 200 só com tarefas de A | |
| 5 | 404 em GET/PUT/PATCH/DELETE na tarefa de B | |
| 6 | 400 | |
| 7 | 201 com id | |
| 8 | 204 e depois 409 | |
| 9 | 200 com usuário e sessões ativas | |
| 10 | 204 e 401 | |
| 11 | conclui os de A, informa os demais | |

Prints em `docs/`:

- `docs/console-sessoes-tempo.png`
- `docs/importador-etapa11.png`

## Relatório

**1. Caminho de um PATCH e de uma linha do importador.**
PATCH `/tarefas/{id}`: `FiltroTempoDeExecucao` → `FiltroAutenticacao` (confere o usuário na sessão) → `FiltroContentType` → `FrontController` (escolhe `ConcluirTarefaCommand` pela chave `PATCH/{id}`) → o command lê o id do caminho e o usuário da sessão e chama `TarefaService.concluir(usuario, id)` → `TarefaServiceImpl` abre a transação, carrega a tarefa com `TarefaDAO.buscar(id, usuarioId)`, chama `Tarefa.concluir()` e grava com `TarefaDAO.atualizar` → MySQL. O command converte o resultado em 204 e o `FrontController` converte as exceções em 404/409/500.
Importador: `main` autentica com `AutenticacaoService.autenticar`, lê a linha e chama `TarefaService.concluir(usuario, id)`; daí para baixo o caminho é o mesmo. Os dois caminhos se encontram em `TarefaService.concluir`.

**2. Conexão, transação e o FiltroConexao.**
Cada operação de serviço usa `Transacao.executar`, que pede uma conexão à `ConnectionFactory`, desliga o auto-commit, faz commit no sucesso e rollback em qualquer exceção, e sempre fecha a conexão. `SQLException` vira `FalhaInternaException`. O `FiltroConexao` foi removido: a conexão presa ao request só funcionava para clientes HTTP, e o importador não passa por filtros. Com a transação na Service Layer, a API e o importador têm o mesmo comportamento atômico, e uma requisição recusada pelo filtro de autenticação nunca abre conexão.

**3. Por que o usuário é parâmetro.**
Porque a Service Layer não pode depender de HTTP. Se as operações lessem a sessão, o importador (que não tem request nem sessão) não conseguiria chamá-las, o serviço passaria a importar `jakarta.servlet` e não seria testável isoladamente. Quem conhece a origem do usuário é o cliente: a API tira da sessão, o importador tira do login por argumentos.

**4. Troca do id de sessão e 404 em vez de 403.**
O id muda no login (`changeSessionId`) para evitar *session fixation*: um id plantado ou conhecido antes do login não passa a valer como sessão autenticada. A tarefa de outro usuário responde 404 porque um 403 confirmaria que aquele id existe, vazando informação; a consulta já filtra por `usuario_id`, então para o usuário a tarefa simplesmente não existe.

**5. Service Layer era necessária?**
Na Tarefa 02 não: havia um único cliente (HTTP) e operações quase CRUD, e os Commands bastavam. Nesta tarefa surgiram um segundo cliente (o importador), regras de acesso por usuário e a exigência de transação comum a todos os clientes. Sem a camada, essas regras seriam duplicadas no importador. A Service Layer passa a ser a fronteira única das operações de negócio.
Para `/auth` foi usado um **Page Controller** (`AuthController`): são só três ações fixas, sem a variedade de rotas que justificou o Front Controller em `/tarefas`, e um servlet simples deixa o fluxo de sessão (criar, trocar id, invalidar) mais legível. Ele só chama `AutenticacaoService` e não acessa DAO nem SQL.
