# Atalho do Sudoku no KUAL

Este guia instala um item **KUAL → Sudoku → Jogar** que abre o KOReader e,
automaticamente, o seletor de modos do Sudoku.

## Pré-requisitos

- Kindle com jailbreak e KUAL funcional;
- KOReader instalado em `/mnt/us/koreader`;
- plugin do Sudoku instalado em `/mnt/us/koreader/plugins/sudoku.koplugin`.

O atalho não instala jailbreak, KUAL nem KOReader. Feche o KOReader antes de
usar o atalho: ele nunca cria uma segunda instância.

## Instalação pelo pacote

1. No computador, execute `sh scripts/package.sh` na raiz deste projeto.
2. Conecte o Kindle por USB e abra a raiz da unidade — ela corresponde a
   `/mnt/us` no aparelho.
3. Extraia `dist/sudoku.koplugin.zip` nessa raiz. Deve resultar em
   `koreader/plugins/sudoku.koplugin/`.
4. Extraia `dist/kual-sudoku.zip` na mesma raiz. Deve resultar em:

   ```text
   extensions/
     sudoku/
       config.xml
       menu.json
       launch.sh
   ```

5. Ejete o Kindle com segurança, desconecte o cabo e abra o KUAL. Escolha
   **Sudoku → Jogar**.

O item grava uma solicitação temporária dentro do plugin, chama
`koreader.sh --kual /mnt/us/documents` e o plugin a consome assim que o
KOReader termina de iniciar. Por isso o seletor de modos aparece sem precisar
tocar no item Sudoku do menu do KOReader.

## Instalação manual (para desenvolvimento)

Com o KOReader fechado, copie:

```text
sudoku.koplugin/  -> /mnt/us/koreader/plugins/sudoku.koplugin/
kual/sudoku/      -> /mnt/us/extensions/sudoku/
```

Use finais de linha LF nos arquivos de shell. O KUAL chama o script com `sh`,
logo ele não depende do bit executável da unidade FAT.

## Uso e saída

- Abra pelo KUAL somente se o KOReader estiver fechado.
- Escolha **Sudoku → Jogar** e selecione o modo desejado.
- Ao tocar **Fechar** dentro de uma partida iniciada pelo KUAL, o KOReader é
  encerrado e seu launcher devolve o Kindle ao ambiente normal.
- Se o KOReader já estiver aberto, abra **Sudoku** pelo menu dele; o atalho
  informa que não inicia uma segunda instância.

## Atualização e diagnóstico

Feche o KOReader antes de substituir qualquer arquivo. Para atualizar, copie
as duas pastas novamente e ejete o Kindle. As partidas salvas ficam no diretório
de dados do KOReader, fora da pasta do plugin.

Se o KUAL não mostrar o item, confirme `extensions/sudoku/config.xml` e
`extensions/sudoku/menu.json`, depois reabra o KUAL. Se abrir somente o
KOReader, habilite o plugin **Sudoku para Kindle** no gerenciador de plugins e
reinicie o KOReader. Consulte também `koreader/plugins/sudoku.koplugin/launcher.log`.

Após desligamento abrupto, o lançador pode encontrar
`koreader/plugins/sudoku.koplugin/launch.lock`. Com o KOReader fechado, remova
somente essa pasta vazia e `launch.request`, se existir; em seguida tente de
novo. Não apague o diretório de dados do KOReader, pois ele contém saves.

## Verificação no computador

```sh
python3 tests/test_kual_launcher.py
sh -n kual/sudoku/launch.sh
sh scripts/run-tests.sh
sh scripts/package.sh
unzip -l dist/kual-sudoku.zip
```

Os testes locais verificam a validação de dependências, a passagem da
solicitação para o KOReader, a remoção de arquivos temporários e a recusa de
destinos inválidos. A abertura final ainda requer validação física no Kindle.
