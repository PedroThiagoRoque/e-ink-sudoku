# Geradores especiais e carregamento cancelável — especificação

Data: 2026-10-07
Estado: design aprovado na conversa; aguardando revisão do documento.

## Objetivo

Completar a geração procedural local dos modos Diagonal, Killer, Kakuro e Samurai e fornecer um diálogo de carregamento cancelável durante qualquer geração. O jogo permanece offline, salva apenas um desafio validado e não altera a partida existente em caso de cancelamento ou falha.

O alvo é Kindle Basic 2 de 8ª geração, firmware 5.16.2.1.1 e KOReader v2025.04. A geração pode durar segundos, mas não pode bloquear a interface.

## Arquitetura

`solver.lua` passa a ser incremental: `step(node_budget)` executa no máximo o orçamento informado e retorna um estado com nós explorados, soluções encontradas, fase e conclusão. Ele interrompe a contagem na segunda solução.

`generator.lua` orquestra tentativas comuns e delega a construção específica para `sudoku/generators/diagonal.lua`, `killer.lua`, `kakuro.lua` e `samurai.lua`. Cada gerador expõe criação de tentativa, avanço cooperativo, estado e resultado. Uma tentativa inválida, sem solução, com múltiplas soluções ou acima do limite de nós é descartada sem criar save.

`generation_controller.lua` executa lotes do gerador e é independente do KOReader. `generation_dialog.lua` usa o controlador com `UIManager:scheduleIn(0, step)`, mostra modo, fase, tentativa e progresso disponível, e oferece **Cancelar**. Cancelar marca o controlador como encerrado, cancela o próximo agendamento e chama somente o callback de cancelamento; não grava ou substitui saves.

O diálogo não conhece regras de Sudoku. Ele recebe apenas o estado do controlador e funções de conclusão, falha e cancelamento.

## Diagonal

Gerar uma solução 9×9 que satisfaz linhas, colunas, blocos 3×3 e as duas diagonais. O gerador usa o solver incremental com as diagonais representadas como unidades de restrição desde o início. Em seguida embaralha as células, remove uma pista por vez e mantém somente remoções cujo solver encontra exatamente uma solução.

## Killer

Gerar uma solução clássica 9×9 e particionar suas 81 células em grupos ortogonalmente conectados de 2–5 células. Cada célula pertence a exatamente um grupo. A soma do grupo é derivada da solução; os valores dentro do grupo devem ser distintos. Pistas fixas podem ser removidas ou mantidas conforme o perfil de dificuldade.

Validar a definição para garantir cobertura total, conectividade de cada grupo, ausência de sobreposição e unicidade considerando linhas, colunas, blocos, somas e não repetição em grupo.

## Kakuro

Criar uma malha de células bloqueadas e jogáveis. Cada sequência horizontal e vertical deve ter 2–9 células; nenhuma célula jogável pode ficar sem sequência nas duas direções. Preencher cada sequência com dígitos 1–9 distintos e derivar as pistas de soma horizontais e verticais.

O formato de desafio mantém apenas células jogáveis, sequências e somas; não aplica unidades de blocos de Sudoku. Validar estrutura, valores distintos, somas e unicidade antes de apresentar ao jogador.

## Samurai

Construir a grade central 9×9 primeiro. Seus quatro blocos de canto se tornam condições fixas das respectivas grades externas. Resolver cada grade externa com a condição compartilhada, preservando uma identidade única para as células de sobreposição. Remover pistas no conjunto inteiro, contando soluções sobre as cinco grades simultaneamente. Nunca validar as cinco grades como problemas isolados.

## Limites e dificuldade

Cada modo define orçamento de nós por passo, limite de nós por tentativa e limite de tentativas. A dificuldade controla quantidade de pistas removidas, faixa de grupos/somas e orçamento de remoções. Ao exceder qualquer limite, a tentativa é abandonada e outra começa usando o PRNG local com a mesma semente-base.

Estados exibidos: `Criando solução`, `Criando grupos`, `Criando malha`, `Removendo pistas`, `Validando solução única`, `Tentativa N` e `Concluído`. O progresso pode ser indeterminado nas fases de busca; nesses casos a tela informa a fase e a tentativa sem percentual falso.

## Integração e persistência

O menu oferece os quatro modos restantes em igualdade com os modos já geráveis. Novo jogo abre o diálogo, e somente no callback de conclusão o controlador cria a sessão e chama o repositório de saves. Continuar carrega o save por modo já existente.

O save contém a definição integral de grupos, sequências, somas e identidades compartilhadas. O cancelamento e falhas não alteram `last-mode.json`, nem o save do modo solicitado.

## Testes e critérios de aceitação

- Solver incremental produz a mesma contagem que o solver atual em lotes variados, respeita orçamento e para na segunda solução.
- Diagonal tem solução única com diagonais válidas.
- Killer cobre todas as células por grupos conectados, sem sobreposição, e tem solução única.
- Kakuro tem apenas sequências válidas de 2–9 células, cada célula jogável pertence a sequência horizontal e vertical, e tem solução única.
- Samurai compartilha os valores das quatro sobreposições e tem solução única no conjunto inteiro.
- Semente e perfil reproduzem o mesmo desafio no computador.
- Cancelar em qualquer fase não grava, não substitui save e encerra o agendamento.
- Diálogo mostra atualização de fase e permite cancelar no KOReader v2025.04.
- Testar fisicamente no Kindle cada gerador, cancelamento, retorno ao menu, suspensão/retomada e retomada posterior por modo.

## Fora de escopo

Pré-geração em segundo plano, sincronização de seeds, garantia de prazo fixo, dicas explicadas e visualização ampliada específica de Samurai/Kakuro.
