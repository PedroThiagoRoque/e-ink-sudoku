# Sudoku para Kindle

Plugin Lua para KOReader no Kindle de 8ª geração. O núcleo contém os modos clássico, diagonal, Mini 4×4 e 6×6, Killer, Kakuro, Mega 16×16 e Samurai. Ele roda offline e grava partidas em JSON com backup.

## Estado atual

O motor, histórico, validação, persistência e catálogo de referência são testados no computador. O plugin aparece no menu principal do KOReader com uma grade tocável, cabeçalho do modo, controles de desfazer/notas/verificação e popup numérico com **Apagar**. A extensão KUAL abre o KOReader somente quando ele ainda não está em execução.

O funcionamento da tela de jogo e a distribuição de dez desafios únicos por conjunto continuam pendentes de validação no Kindle com as versões reais de firmware, KUAL e KOReader. Não há declaração de compatibilidade física antes dessa validação.

## Instalação de desenvolvimento

1. Copie `sudoku.koplugin` para `/mnt/us/koreader/plugins/`.
2. Copie `kual/sudoku` para `/mnt/us/extensions/sudoku/`.
3. Reinicie o KOReader. No menu principal, escolha **Sudoku**.
4. Pelo KUAL, use **Abrir Sudoku no KOReader**, depois abra o item Sudoku dentro do menu do KOReader.

As partidas ficam em diretório de dados definido pela integração do KOReader. Ao implementar essa ligação no aparelho, use `Storage.save`: ele escreve arquivo temporário e mantém a última cópia como `.bak`. Se um save ficar corrompido, a rotina de carga tenta o `.bak`; não apague o arquivo original antes de confirmar a recuperação.

## Verificação local

```sh
sh scripts/run-tests.sh
luac -p sudoku.koplugin/main.lua sudoku.koplugin/sudoku/*.lua sudoku.koplugin/catalog/*.lua
sh scripts/package.sh
```

O sistema de arquivos deste ambiente não executa scripts diretamente; use `sh` como acima.

## Validação no Kindle requerida

Registre modelo, firmware, versão de KOReader e versão de KUAL. Teste abertura pelo KUAL, retorno ao KOReader, toque, suspensão e retomada, salvamento e recuperação, legibilidade após 100 ações e cada variante. Meça também abertura, memória e latência visual antes de tratar a versão como distribuível.
