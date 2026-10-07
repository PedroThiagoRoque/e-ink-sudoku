# Sudoku confiável em tela cheia — especificação

Data: 2026-10-07
Estado: desenho aprovado em conversa; aguardando revisão do documento

## Objetivo

Entregar uma primeira versão confiável do Sudoku para Kindle Basic 2 de 8ª
geração, firmware 5.16.2.1.1 e KOReader v2025.04. A versão oferece Clássico
9×9, Mini 4×4, Mini 6×6 e Mega 16×16, funciona offline, ocupa toda a tela e
permite gerar, jogar, interromper e retomar partidas sem corromper dados.

A dificuldade padrão é **Média**, comparável no modo Clássico a um Sudoku
intermediário de revista. A interface limpa todo o fundo antes de desenhar o
jogo e usa atualizações adequadas à tela e-ink.

Diagonal, Killer, Kakuro e Samurai permanecem fora do menu distribuído até
possuírem gerador, representação visual e critérios de aceitação próprios.
Código experimental desses modos não constitui funcionalidade entregue.

## Problemas confirmados na implementação atual

### Geração e regras

- Diagonal, Killer, Kakuro e Samurai caem silenciosamente no gerador clássico
  9×9, preservando apenas o nome do modo. O resultado não contém diagonais,
  somas, cages, sequências ou as cinco grades Samurai.
- `Generator:step` e `Solver:step` ignoram o orçamento recebido e executam a
  busca inteira de forma síncrona. O cancelamento não pode ser processado
  durante o trabalho. Mega difícil levou cerca de 3,2 segundos de CPU no
  computador em uma única chamada; o tempo no Kindle ainda não foi medido.
- O solver aceita um tabuleiro totalmente preenchido e contraditório como uma
  solução porque não valida o estado terminal.
- O modelo não valida referências, tipos, duplicações, cobertura ou demais
  invariantes de grupos de soma. Uma definição malformada pode ser ignorada ou
  provocar erro durante a validação.
- O validador pode considerar resolvidos valores que não pertencem ao conjunto
  de símbolos quando o estado não passou por `Game:set_value`.
- O gerador fácil remove somente quatro pistas. Por isso o Clássico atual pode
  oferecer apenas quatro ou cinco células relevantes para preencher e parecer
  uma demonstração incompleta.
- As dificuldades atuais usam apenas quantidades fixas de remoções e não medem
  técnicas ou esforço de resolução. Mini 4×4 médio e difícil podem produzir o
  mesmo resultado; Mega permanece quase todo preenchido.
- O catálogo contém estruturas de referência vazias ou parciais, não desafios
  únicos prontos para jogar.

### Persistência e ciclo de vida

- Notas numéricas esparsas são serializadas como arrays truncados contendo
  `null`; o leitor não aceita `null`. Uma anotação pode tornar o save e o
  backup impossíveis de carregar.
- Uma entrada é salva pelo callback do jogo e novamente pelo tabuleiro. A
  segunda gravação substitui o backup por uma cópia idêntica e elimina a versão
  anterior útil.
- Desfazer e refazer não notificam alteração. Fechar depois de desfazer mantém
  no disco a jogada que deveria ter sido removida.
- Resultados de escrita e fechamento do arquivo são ignorados. Falta de espaço
  pode ser reportada como sucesso e nenhum chamador mostra erro ao jogador.
- O seletor de modos permanece aberto e captura o save disponível no momento
  de sua criação. Depois de criar uma partida, ele pode gerar outra por engano
  ou reabrir uma sessão antiga sobre o save novo.
- Geração agendada, popup numérico, seletor e tabuleiro não têm um proprietário
  único capaz de fechar widgets e cancelar tarefas ao sair.

### Interface e distribuição

- A grade atual é uma tabela de botões iguais. Ela não desenha notas,
  diferenças entre pista e entrada, blocos, conflitos, diagonais, cages ou
  somas, e não informa conclusão.
- O Samurai real usa IDs como `r1:c1`; a interface fabrica IDs como `1:1`, de
  modo que os toques não selecionam células reais.
- `Verificar` apenas redesenha a mesma tela e `Apagar` não tem comportamento
  útil no modo de notas.
- A dificuldade é fixada em `easy`; não existe seleção, confirmação para
  substituir save ou retomada global coerente.
- O ZIP do plugin contém `sudoku.koplugin/` na raiz, mas o tutorial instrui a
  extração na raiz do Kindle esperando
  `koreader/plugins/sudoku.koplugin/`. Seguir a instrução literalmente instala
  o plugin no lugar errado.
- O executor principal roda apenas testes Lua. Ele não inclui os testes KUAL,
  sintaxe, manifestos nem estrutura dos pacotes, e os testes do gerador não
  demonstram a unicidade anunciada por seus nomes.

## Escopo da versão confiável

### Modos entregues

| Modo | Tamanho | Regiões | Símbolos |
| --- | ---: | --- | --- |
| Clássico | 9×9 | 3×3 | 1–9 |
| Mini 4×4 | 4×4 | 2×2 | 1–4 |
| Mini 6×6 | 6×6 | 2×3 | 1–6 |
| Mega | 16×16 | 4×4 | 1–9 e A–G |

Cada partida entregue deve ter definição estrutural válida, solução única e
perfil de dificuldade aceito. Um modo só aparece no menu quando esses critérios
são cobertos por testes automatizados.

### Fluxo principal

```text
KUAL ou menu do KOReader
    → Continuar ou Novo jogo
    → modo e dificuldade
    → confirmação de substituição, se houver save
    → geração incremental cancelável
    → validação final
    → tela cheia do jogo
    → salvamento automático
    → retorno ao KOReader ou encerramento da sessão KUAL
```

Cancelar ou falhar durante a geração preserva a partida anterior. O novo save
só substitui o anterior depois que a definição final foi validada.

## Arquitetura

### Núcleo de restrições incremental

O solver mantém explicitamente a pilha da busca entre chamadas. Cada
`step(node_budget)` visita no máximo o orçamento informado, atualiza o estado e
devolve o controle. O resultado distingue em andamento, sem solução, solução
única e duas ou mais soluções.

Antes da busca, a definição é compilada e validada:

- células, símbolos e IDs são únicos e consistentes;
- toda unidade referencia células existentes sem duplicação;
- valores iniciais pertencem aos símbolos e não entram em conflito;
- dimensões e blocos são compatíveis com o modo;
- índices de unidades por célula são construídos uma vez.

O solver consulta somente restrições afetadas pela célula corrente. Ele não
executa uma inspeção completa para cada candidato. O estado terminal passa pelo
mesmo validador usado pelo jogo antes de ser contado como solução.

### Gerador dos modos regulares

O gerador é uma máquina de estados cooperativa:

1. cria uma solução completa com permutações de símbolos, linhas, colunas e
   bandas compatíveis com os blocos;
2. define uma ordem reprodutível de remoção, preferencialmente simétrica;
3. tenta remover pistas em pequenos lotes;
4. usa o solver incremental para preservar solução única;
5. avalia a dificuldade;
6. aceita, tenta novas remoções ou inicia nova tentativa;
7. valida novamente a definição final antes de publicá-la.

Modo desconhecido ou dificuldade desconhecida produz erro explícito. Não há
fallback silencioso para Clássico. Semente, modo, dificuldade, tentativa e
métricas do perfil fazem parte da definição persistida.

### Controlador de aplicação

Um controlador possui o seletor, o trabalho de geração, a tela de jogo e os
diálogos auxiliares. Transições fecham o widget anterior antes de abrir o
próximo. Sair cancela tarefas agendadas, fecha todos os widgets próprios, tenta
salvar a sessão e só então devolve o controle ao KOReader.

O controlador consulta o repositório quando o jogador escolhe **Continuar**;
callbacks não capturam snapshots antigos. Erros de geração, validação e
persistência são convertidos em mensagens compreensíveis, sem encerrar o
KOReader.

## Dificuldade de revista

### Perfil padrão do Clássico

**Médio** é o padrão. Um puzzle Clássico médio deve:

- ter entre 30 e 36 pistas, usadas como faixa auxiliar e não como
  prova isolada de dificuldade;
- possuir exatamente uma solução;
- ser resolvido pelo avaliador lógico sem adivinhação;
- exigir uma combinação de candidatos únicos, únicos ocultos, candidatos
  bloqueados e pares simples;
- exceder o teto de pontuação do perfil Fácil e permanecer abaixo do teto do
  Difícil.

O avaliador registra técnica, quantidade de aplicações e progresso produzido.
Se uma etapa exigir busca especulativa antes de atender ao perfil, a tentativa
não é classificada como Médio. As faixas exatas de pontuação ficam em uma
tabela configurável e são calibradas por amostras reproduzíveis, não espalhadas
em condicionais.

Mini e Mega usam perfis relativos ao tamanho da grade, combinando proporção de
pistas, unicidade e esforço normalizado do solver. Eles não são descritos como
equivalentes editoriais exatos ao Clássico.

## Tela cheia para e-ink

A partida usa um widget gráfico próprio do KOReader, em tela inteira. Na
abertura, ele preenche toda a superfície com branco e solicita atualização
completa antes de desenhar o jogo. Nenhuma barra do KOReader permanece visível.

### Layout

```text
┌──────────────────────────────┐
│ Clássico · Médio      estado │
├──────────────────────────────┤
│                              │
│       grade centralizada     │
│                              │
├──────────────────────────────┤
│ teclado de símbolos          │
│ Desfazer  Refazer  Notas     │
│ Verificar  Redesenhar  Sair  │
└──────────────────────────────┘
```

O layout deriva todas as dimensões da área útil da tela. Mini usa células
maiores e grade centralizada; Mega usa células menores e teclado em duas
linhas. Alvos de toque não podem ser menores que a célula visual.

### Desenho e interação

- Linhas de bloco são mais espessas que linhas internas.
- Pistas e entradas usam pesos ou estilos distintos sem depender de cor.
- Seleção usa contorno grosso; conflitos usam contorno duplo ou inversão.
- Notas são posicionadas em uma subgrade dentro da célula.
- O teclado contém somente símbolos do modo e uma ação explícita de apagar.
- Em modo de notas, apagar permite limpar as notas da célula selecionada.
- Desfazer e refazer atualizam tela e save.
- Verificar informa vazios e conflitos; conclusão válida abre confirmação.
- Redesenhar solicita atualização completa manual para remover ghosting.

A abertura, troca estrutural de tela e redesenho manual usam atualização
completa. Movimentos usam atualização parcial da menor região segura. Uma
política configurável solicita atualização completa periódica após um número
de ações para controlar ghosting no aparelho.

## Persistência

O save recebe uma versão nova e contém:

- modo, dificuldade, semente, tentativa e métricas;
- definição completa do puzzle;
- valores, notas, seleção e modo de notas;
- histórico de desfazer/refazer em formato validado.

Notas são representadas por listas ordenadas de símbolos, nunca por mapas
numéricos esparsos. O leitor valida símbolos, células, snapshots e coerência
com a definição antes de construir uma sessão. Saves antigos válidos são
migrados; arquivos incompatíveis ou corrompidos são preservados.

### Escrita segura

1. serializar o registro;
2. escrever, descarregar e fechar o arquivo temporário, conferindo retornos;
3. reler e validar o temporário;
4. mover o save atual para `.bak`;
5. promover o temporário;
6. restaurar o backup se a promoção falhar.

Cada comando lógico dispara no máximo um salvamento. Seleção, entrada, notas,
desfazer, refazer e fechamento preservam o estado. Se a escrita falhar, a
partida permanece em memória e a interface mostra o erro e permite tentar
novamente.

## Tratamento de erros

- Falha de validação ou unicidade descarta apenas a tentativa temporária.
- Exceder o limite de tentativas preserva o save e oferece tentar outra semente.
- Cancelar encerra o trabalho agendado e não chama callbacks de conclusão.
- Fechar durante popup ou geração cancela tarefas e fecha todos os widgets.
- Save corrompido tenta o `.bak`; nenhuma recuperação apaga automaticamente os
  arquivos problemáticos.
- Falhas do KUAL e do plugin são registradas em log e apresentadas sem deixar
  locks ou solicitações obsoletas.

## Distribuição

O pacote do plugin extraível na raiz do Kindle contém:

```text
koreader/plugins/sudoku.koplugin/
```

O pacote KUAL contém:

```text
extensions/sudoku/
```

Tutorial, conteúdo dos ZIPs e verificações automatizadas usam exatamente esses
caminhos. A atualização substitui o código sem remover o diretório de saves.

## Testes e critérios de aceitação

### Núcleo

- Definições inválidas são rejeitadas antes da busca.
- Solver retorna zero, uma ou duas soluções e rejeita estado terminal inválido.
- Cada passo respeita o orçamento e pode ser cancelado entre lotes.
- Mesma semente e perfil produzem a mesma definição completa.
- Clássico, Mini 4×4, Mini 6×6 e Mega produzem puzzles válidos e únicos.
- O avaliador lógico aceita amostras médias e rejeita amostras fora do perfil.
- O Clássico médio atende à faixa auxiliar de 30–36 pistas.

### Partida e persistência

- Valores, notas, seleção, modo de notas e histórico sobrevivem à reabertura.
- Notas com símbolos 2, 9 e A–G fazem round-trip sem `null` ou perda.
- Uma ação produz uma gravação; desfazer/refazer também persistem.
- Falhas de escrita, fechamento e rename preservam dados e chegam à interface.
- Save truncado tenta backup e mantém o arquivo original.

### Interface e integração

- Layout e toque são testados em resoluções representativas do Kindle.
- A grade desenha linhas de bloco, pistas, entradas, notas e conflitos.
- Abrir limpa o fundo; movimento atualiza região parcial; redesenhar atualiza a
  tela completa.
- Seletor, popup, geração e tabuleiro não permanecem órfãos após transições.
- Runner executa testes Lua, testes KUAL, sintaxe, manifestos e conteúdo dos
  pacotes.
- ZIPs são extraídos em diretório temporário e comparados à estrutura
  documentada.

### Validação física obrigatória

No Kindle alvo, registrar versões e verificar:

- abertura pelo KUAL e pelo KOReader;
- fundo realmente limpo e ausência de barras do KOReader;
- legibilidade e precisão de toque nos quatro tamanhos;
- geração, progresso, cancelamento e responsividade;
- notas, conflitos, conclusão, desfazer/refazer e retomada;
- suspensão, retomada, rotação suportada e saída;
- ghosting, tempo de abertura, memória e latência após pelo menos 100 ações.

Compatibilidade física só é declarada após essa validação.

## Fora de escopo desta versão

- Diagonal, Killer, Kakuro e Samurai;
- sincronização entre dispositivos e compartilhamento de sementes;
- dicas explicadas passo a passo;
- garantia de duração fixa para geração;
- animações contínuas ou elementos dependentes de cor.
