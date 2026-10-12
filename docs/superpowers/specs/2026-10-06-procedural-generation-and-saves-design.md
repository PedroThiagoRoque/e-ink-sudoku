# Geração procedural e retomada por modo — especificação

Data: 2026-10-06
Estado: design aprovado em conversa; aguardando revisão do documento.

## Objetivo

Permitir criar no próprio Kindle desafios inéditos para todos os modos do Sudoku e retomar, após fechar e reabrir o KOReader, a última partida de cada modo. A geração pode durar alguns segundos, desde que permaneça responsiva e indique seu progresso.

O alvo é Kindle Basic 2 de 8ª geração, firmware 5.16.2.1.1, KOReader v2025.04. KUAL está instalado, mas sua versão não foi identificada pelos arquivos USB. A solução permanece offline.

## Experiência do jogador

O menu do Sudoku mostra cada modo com duas ações:

- **Continuar** aparece somente quando há uma partida daquele modo; abre a última partida salva.
- **Novo jogo** pede modo e dificuldade, mostra confirmação caso substitua uma partida existente e inicia a geração.

O item global **Continuar** abre a partida do último modo usado. `Novo jogo` substitui apenas o save do modo escolhido; saves dos demais modos não são alterados.

A tela de geração mostra o modo, a fase e o percentual estimado: `Criando solução`, `Removendo pistas`, `Criando grupos`, quando aplicável, e `Validando solução única`. Ela tem o botão **Cancelar**. O cancelamento deixa intacto o save existente e retorna ao menu. A tela não usa animações contínuas; atualiza somente quando uma unidade de trabalho é concluída.

## Arquitetura

### Motor de restrições e solução

Adicionar um solucionador de satisfação de restrições independente de KOReader, usando as unidades sem repetição e grupos de soma já representados no modelo de desafio. Ele recebe uma definição parcial e procura no máximo duas soluções. O resultado é `0`, `1` ou `2+`; `2+` basta para rejeitar o desafio e evita trabalho desnecessário.

O solucionador escolhe a célula não preenchida com menos candidatos, embaralha candidatos por gerador pseudoaleatório local e executa em passos limitados. Um objeto de trabalho retém a busca entre chamadas, permitindo que a interface execute lotes pequenos via agendamento do `UIManager` e permaneça capaz de cancelar.

O gerador pseudoaleatório recebe uma semente inteira criada ao iniciar `Novo jogo`. Nenhuma chamada ao gerador global do Lua pode afetar a reprodução. Semente, tentativas e parâmetros de dificuldade são armazenados no desafio final.

### Geradores por modo

| Modo | Construção | Validação |
| --- | --- | --- |
| Clássico | Solução 9×9 aleatória; remover pistas. | Unidades padrão; exatamente uma solução. |
| Diagonal | Solução 9×9 com diagonais; remover pistas. | Linhas, colunas, blocos e diagonais; exatamente uma solução. |
| Mini 4×4 e 6×6 | Solução com blocos 2×2 ou 2×3; remover pistas. | Unidades do tamanho correspondente; exatamente uma solução. |
| Mega | Solução 16×16 e blocos 4×4; remover pistas. | Unidades 16×16; exatamente uma solução. |
| Killer | Solução clássica; particionar em grupos ortogonalmente conectados de 2–5 células; usar suas somas. | Unidades clássicas, soma e não repetição em grupo; exatamente uma solução. |
| Kakuro | Padrão de células bloqueadas e sequências de 2–9 casas; preencher dígitos distintos e derivar pistas. | Cada sequência satisfaz sua soma e não repete dígitos; exatamente uma solução. |
| Samurai | Cinco soluções 9×9 compatíveis nos blocos sobrepostos; remover pistas no conjunto. | Cada sobreposição é uma mesma célula lógica; conjunto inteiro tem exatamente uma solução. |

Cada gerador tem limites de nós, tentativas e tempo por tentativa. Ultrapassar um limite descarta aquela tentativa e inicia outra com a próxima sequência do PRNG. A tela informa tentativas sem prometer duração fixa. Cancelar interrompe a tentativa atual e descarta somente o resultado temporário.

### Dificuldade

Os níveis iniciais são **Fácil**, **Médio** e **Difícil**. Um perfil por modo fixa intervalo de pistas/grupos, orçamento de remoções e limite de esforço do solucionador. A dificuldade é aceita somente se os valores medidos ficarem no perfil; caso contrário, o desafio é descartado. Os limites vivem em dados configuráveis, não espalhados pelo gerador, para ajuste após medições no Kindle.

## Persistência

Cada modo usa um save independente no diretório de dados do plugin:

```text
saves/classic.json
saves/diagonal.json
saves/mini-4.json
saves/mini-6.json
saves/killer.json
saves/kakuro.json
saves/mega.json
saves/samurai.json
saves/last-mode.json
```

O save contém versão, modo, identificador, semente, dificuldade, definição completa do desafio, valores, notas, histórico de desfazer/refazer, célula selecionada e modo de notas. A definição completa é necessária porque o desafio não pode depender de um catálogo distribuído nem de uma nova geração para ser retomado.

Salvar após cada valor, nota, desfazer/refazer, seleção e troca do modo de notas. Usar a escrita temporária e backup `.bak` existente. Um save corrompido ou incompatível é preservado, tenta o `.bak` e, se ambos falharem, apresenta `Nova partida` sem apagar o arquivo original. Erro de escrita é exibido, mantendo o estado em memória para tentativa posterior.

## Integração KOReader

O menu de plugin passa a carregar `last-mode.json`, inspecionar saves por modo e abrir uma tela de seleção de modo. O tabuleiro recebe um callback de alteração que solicita o salvamento e atualiza a última modalidade. O fechamento do tabuleiro salva novamente como proteção contra mudanças futuras que não dispararem callback.

O controlador de geração usa `UIManager:scheduleIn(0, step)` ou API equivalente confirmada na versão v2025.04. Cada `step` executa orçamento pequeno de nós e então redesenha somente o texto que mudou. Ao concluir, o controlador cria sessão, grava o save inicial e abre o tabuleiro. Ao cancelar, fecha a tela de carregamento e não grava nada.

## Erros e limites

- Desafio inválido, sem solução ou com múltiplas soluções não chega ao jogador.
- Falha repetida além do limite global mostra mensagem e oferece tentar novamente com nova semente.
- O solver não executa Lua carregado do save; o JSON é tratado como dados e validado contra o modelo.
- O gerador não substitui um save até ter validado integralmente um novo desafio e recebido confirmação do jogador.
- Grades Mega e Samurai podem ser paginadas na interface atual; uma visão ampliada é trabalho posterior e não muda o formato de desafio nem save.

## Testes e aceitação

- O solucionador conta zero, uma e múltiplas soluções; para na segunda solução.
- A mesma semente e perfil produzem a mesma definição no computador.
- Cada gerador produz desafio estruturalmente válido, solucionável e com uma solução para todos os modos.
- Killer rejeita grupos desconectados, repetição e soma errada; Kakuro rejeita sequência inválida; Samurai preserva identidade nas áreas compartilhadas.
- O cancelamento não cria ou altera saves.
- Save por modo sobrevive a fechamento/reabertura, incluindo notas, histórico, seleção e modo de notas; novo jogo de um modo não altera os demais.
- Arquivo truncado, versão incompatível, backup e falha de gravação seguem a política de recuperação descrita.
- No Kindle, validar geração e retomada em todos os modos, atualização da tela de carregamento, cancelamento, suspensão/retomada e legibilidade após 100 ações.

## Fora de escopo

Sincronização entre dispositivos, compartilhamento de sementes, geração em segundo plano após sair do jogo, ranking, dicas explicadas e garantia de que todas as gerações terminam em prazo fixo.

## Decomposição proposta

1. Solver cooperativo, PRNG reproduzível e serialização de definição de desafio.
2. Geração e save/retomada para Clássico, Diagonal e Mini.
3. Perfis de dificuldade, menu de modo e tela de carregamento cancelável.
4. Killer e Kakuro, com seus construtores e restrições.
5. Mega e Samurai, com limites de desempenho ajustados no Kindle.
6. Medição e ajustes físicos no dispositivo.
