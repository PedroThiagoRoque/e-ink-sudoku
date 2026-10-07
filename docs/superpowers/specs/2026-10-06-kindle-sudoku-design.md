# Sudoku para Kindle — especificação de arquitetura

Data: 2026-10-06
Estado: arquitetura aprovada na conversa; especificação escrita para revisão.

## Objetivo e contexto

Desenvolver um jogo offline, em português, para Kindle de 8ª geração com jailbreak. O usuário aprovou a execução como plugin do KOReader, com acesso pelo KUAL, e os modos clássico, diagonal, Kakuro, Killer, Mega 16×16, Mini e Multi/Samurai. O repositório ainda não contém implementação.

O produto deve permitir jogar, interromper e retomar uma partida confortavelmente em tela e-ink. A versão do firmware e as versões instaladas de KUAL e KOReader ainda não foram informadas; a primeira entrega deve registrar e validar essa combinação no aparelho. Não se presume que jailbreak confirme a instalação dos outros componentes.

## Decisões de arquitetura

- Plugin `sudoku.koplugin` em Lua, usando os componentes de interface, entrada e atualização de tela do KOReader.
- Motor de regras independente da interface, testável no computador e compatível com o runtime Lua da versão de KOReader validada.
- Extensão KUAL para iniciar o KOReader pelo mecanismo de lançamento compatível com a instalação existente. Abrir diretamente o jogo é um objetivo do protótipo, não uma capacidade já comprovada.
- Se a abertura direta não for suportada de forma confiável, a entrega inicial deve abrir o KOReader e documentar o acesso ao jogo pelo menu. Não alterar scripts do KOReader silenciosamente nem iniciar uma segunda instância.
- Catálogo offline de desafios previamente gerados e validados no computador. Geração no próprio Kindle fica fora da primeira versão.
- Uma única interface de jogo; não haverá aplicativo independente com acesso próprio ao framebuffer nesta versão.

## Modos e regras

| Modo | Definição |
| --- | --- |
| Clássico | 9×9, valores 1–9, linhas, colunas e blocos 3×3 sem repetição. |
| Diagonal | Clássico com valores 1–9 sem repetição em cada uma das duas diagonais principais. |
| Mini | 4×4 com blocos 2×2 e valores 1–4; 6×6 com blocos de 2 linhas por 3 colunas e valores 1–6. |
| Killer | Grade 9×9 com regras clássicas e grupos conectados ortogonalmente que particionam as células; cada grupo tem soma indicada e proíbe repetição. Pistas fixas são permitidas. |
| Mega | 16×16, blocos 4×4, valores internos 1–16 exibidos como 1–9 e A–G. |
| Kakuro | Células bloqueadas, pistas de soma e células jogáveis; cada sequência horizontal ou vertical tem de 2 a 9 células, valores 1–9 distintos e soma igual à pista. Não aplica blocos de Sudoku. |
| Multi/Samurai | Cinco grades 9×9 em disposição Samurai, dentro de uma área lógica 21×21; a grade central compartilha seus quatro blocos de canto com as quatro grades externas. Espaços entre grades não são jogáveis. |

No Samurai, cada célula compartilhada tem identidade e valor únicos, sujeitos às restrições de ambas as grades. O validador de catálogo deve verificar a solução única do conjunto, não apenas de cada grade isolada.

## Experiência de jogo

Fluxo principal: menu do plugin → modo → tamanho, quando aplicável → dificuldade → desafio → partida. O menu também oferece continuar partidas salvas. Cada desafio pode manter uma partida em andamento; reiniciar exige confirmação para não apagar progresso acidentalmente.

A partida oferece seleção por toque, teclado de valores, modo de notas manuais, apagar, desfazer, refazer, verificar conflitos e retornar ao menu. Pistas originais são imutáveis. Uma nova ação após desfazer descarta o ramo de refazer. Não haverá dicas automáticas ou remoção automática de candidatos na primeira versão.

Notas não são consideradas valores na validação. Verificar conflitos mostra violações das regras conhecidas, sem comparar secretamente cada entrada com a solução. No Killer e Kakuro, deve detectar repetições, somas excedidas e sequências completas com soma incorreta. A vitória exige todas as células preenchidas e todas as restrições satisfeitas.

Clássico e Mini usam uma grade completa quando legível. Mega e Samurai oferecem visão geral e visão ampliada de uma região, com indicação permanente da posição selecionada. O usuário pode navegar sem depender de gestos complexos; a visão geral não exige acertar células minúsculas. As somas do Killer e Kakuro precisam permanecer legíveis na visão ampliada.

Usar alto contraste, linhas que diferenciem blocos e grupos e marcações que não dependam de cor. Evitar animações e atualizações periódicas enquanto a tela estiver parada. Solicitar atualizações pelo KOReader e validar ghosting no aparelho; oferecer redesenho completo manual. Dimensões dos controles devem acompanhar a área útil informada pelo dispositivo.

## Componentes e responsabilidades

1. **Modelo de desafio:** versão do formato, ID estável, modo, dimensões, símbolos, células, pistas, unidades sem repetição, grupos de soma e metadados de dificuldade. Células compartilhadas usam a mesma identidade.
2. **Motor de regras:** valida estruturas e movimentos, identifica conflitos e verifica conclusão. Não conhece widgets, arquivos nem dispositivos.
3. **Estado de partida:** valores, notas, seleção, região visível e histórico de desfazer/refazer. Aplica comandos e mantém pistas protegidas.
4. **Interface KOReader:** menus, desenho, teclado, navegação e feedback; converte toque em comandos de partida.
5. **Persistência:** arquivos locais versionados por desafio, gravação atômica com arquivo temporário no mesmo diretório e cópia anterior recuperável.
6. **Catálogo e ferramentas de autoria:** geração ou importação no computador, validação estrutural, contagem de soluções e empacotamento dos desafios.
7. **Integração e distribuição:** metadados do plugin, extensão KUAL, instalação por cópia e documentação de compatibilidade.

Fluxo de dados: catálogo validado → modelo → estado da partida → comando do usuário → motor de regras → persistência e atualização da região afetada da interface.

## Persistência e falhas

Salvar após cada alteração de valor ou nota e ao sair. Preservar histórico de desfazer/refazer na retomada. Salvar seleção e posição de navegação ao sair ou suspender, conforme os eventos disponíveis na versão validada.

Ao carregar, validar versão, identidade do desafio e integridade dos dados. Um arquivo incompatível ou corrompido deve produzir mensagem compreensível, preservar o original e permitir recuperar a cópia anterior ou iniciar nova partida. Não interpretar dados de desafio ou salvamento como código executável.

Falha de gravação deve ser visível e manter o estado em memória para uma nova tentativa. Um desafio inválido deve ser recusado sem encerrar o KOReader. A instalação e atualização do plugin devem preservar as partidas salvas.

## Catálogo e dificuldade

Cada um dos oito conjuntos — clássico, diagonal, Mini 4×4, Mini 6×6, Killer, Mega, Kakuro e Samurai — terá pelo menos 10 desafios únicos na primeira distribuição. Todos precisam ter exatamente uma solução comprovada por ferramenta de validação, interrompendo a busca ao encontrar a segunda solução. A solução usada pela ferramenta não precisa ser distribuída ao jogador.

Disponibilizar somente categorias de dificuldade sustentadas pelo classificador de cada modo. As categorias são relativas ao modo; quantidade de pistas isoladamente não define dificuldade. A primeira entrega pode oferecer uma única categoria por conjunto, identificada como “padrão”; fácil, médio e difícil só entram após critérios reproduzíveis e testes de resolução. Isso evita prometer classificação ainda não medida.

## Entregas e dependências

1. **Compatibilidade:** protótipo mínimo de plugin no aparelho, entrada por toque, redesenho, saída, suspensão/retomada e lançamento via KUAL; registrar versões e o comportamento real do acesso direto.
2. **Jogo básico:** modelo, regras clássicas e Mini, interface jogável, catálogo inicial, histórico e salvamento recuperável.
3. **Restrições adicionais:** diagonal e Killer, incluindo apresentação e verificação das somas.
4. **Kakuro:** modelo de sequências e pistas, regras e apresentação específica.
5. **Grades grandes:** Mega e Samurai, visão geral, ampliação e compartilhamento consistente de células.
6. **Distribuição:** completar os oito conjuntos do catálogo, executar testes no aparelho, empacotar e documentar instalação, atualização e recuperação.

Detalhar a implementação em planos separados para compatibilidade, núcleo jogável, modos adicionais e distribuição. O resultado do protótipo determina as APIs de integração e os comandos de teste posteriores; não fixar versões ou APIs ainda não verificadas.

## Critérios de aceitação e testes

- Cada modo aceita soluções corretas e rejeita violações específicas, com testes automatizados de regras e casos inválidos.
- Testar especialmente diagonais na célula central, repetição e soma em grupos, símbolos de Mega, blocos retangulares de Mini e restrições simultâneas nas sobreposições de Samurai.
- Validar todos os desafios distribuídos quanto à estrutura, preservação de pistas e solução única; rejeitar desafios sem solução ou com múltiplas soluções.
- Valores, notas e histórico sobrevivem a fechamento e reabertura; testar arquivo truncado, versão desconhecida, falha de gravação e recuperação de backup.
- Pistas não podem ser apagadas ou modificadas por teclado, desfazer ou carregamento inválido.
- No Kindle alvo, jogar e retomar pelo menos uma partida de cada conjunto, incluindo entrada e exclusão de notas, navegação e saída.
- Registrar latência de entrada, consumo de memória e tempo de abertura no aparelho. Meta inicial: feedback visual em até 300 ms para 95% das entradas em uma sequência de 100 ações por modo, com método de medição documentado; caso não seja atingida, otimizar ou renegociar a meta antes da distribuição.
- Após suspensão/retomada, manter partida e toque funcionais. Validar legibilidade de todas as pistas e ausência de ghosting que impeça leitura após 100 ações, usando redesenho completo quando necessário.
- KUAL deve iniciar o caminho documentado sem duplicar instâncias; sair do jogo deve devolver o controle ao KOReader.
- Entrega só pode afirmar compatibilidade com a combinação de aparelho, firmware e KOReader efetivamente testada. Verificação no computador não substitui teste físico.

## Fora do escopo inicial

Multiplayer, contas, sincronização em nuvem, rankings, geração no Kindle, dicas com explicação, aplicativo independente e suporte garantido a outros modelos. “Multi” significa Samurai, não multiplayer.

## Referências técnicas

- Estrutura de plugin Lua no repositório oficial do KOReader: https://github.com/koreader/koreader/blob/master/plugins/kosync.koplugin/main.lua
- Documentação do autor do KUAL e estrutura de extensões: https://www.mobileread.com/forums/showthread.php?t=203326

As referências justificam a proposta de integração; o protótipo precisa confirmar as APIs e o mecanismo de lançamento nas versões instaladas.
