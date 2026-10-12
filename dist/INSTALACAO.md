# Instalação no Kindle

Este diretório contém dois pacotes:

- `sudoku.koplugin.zip`: o jogo como plugin do KOReader.
- `kual-sudoku.zip`: atalho opcional para o KUAL abrir diretamente o seletor do jogo.

O Kindle precisa ter jailbreak, KOReader e, para o atalho opcional, KUAL instalados.

## 1. Conectar o Kindle

Conecte o Kindle por USB. No computador ele aparece como uma unidade com pastas como `documents`, `koreader` e `extensions`.

Feche o KOReader no Kindle antes de atualizar o plugin.

## 2. Instalar o plugin do jogo

Extraia `sudoku.koplugin.zip` na raiz da unidade do Kindle. O resultado precisa ficar assim:

```text
koreader/
  plugins/
    sudoku.koplugin/
      _meta.lua
      main.lua
      sudoku/
      catalog/
```

Ou seja, copie a pasta extraída `sudoku.koplugin` para:

```text
/mnt/us/koreader/plugins/sudoku.koplugin/
```

Não deixe uma pasta adicional como `sudoku.koplugin/sudoku.koplugin/`.

## 3. Instalar o atalho do KUAL (opcional)

Extraia `kual-sudoku.zip` na raiz da unidade do Kindle. O resultado precisa ficar assim:

```text
extensions/
  sudoku/
    config.xml
    menu.json
    launch.sh
```

O destino no Kindle é:

```text
/mnt/us/extensions/sudoku/
```

Com o KOReader fechado, use **KUAL → Sudoku → Jogar**. O atalho abre o
KOReader e o plugin mostra automaticamente o seletor de modos. Se o KOReader
já estiver aberto, abra **Sudoku** pelo menu dele; o atalho não cria uma segunda
instância.

## 4. Ejetar e abrir

Ejete a unidade USB corretamente e desconecte o cabo. Abra o KUAL e selecione
**Sudoku → Jogar**.

## Atualização

Feche o KOReader, substitua somente a pasta `koreader/plugins/sudoku.koplugin` pela versão nova e reinicie o KOReader. As partidas ficam no diretório de dados do KOReader, separado da pasta do plugin, e devem ser preservadas.

Se a atualização não carregar, remova apenas `koreader/plugins/sudoku.koplugin`, extraia novamente o ZIP e confirme a estrutura de pastas acima. Não remova o diretório de dados do KOReader, pois ele pode conter os saves.

Para diagnóstico do atalho, consulte `launcher.log` dentro do plugin. Se um
desligamento abrupto deixar `launch.lock`, feche o KOReader e remova somente
essa pasta vazia e `launch.request`, se existir.

## Estado atual

Clássico, Mini e Mega têm geração local e retomada de partida. Diagonal, Killer, Kakuro e Samurai ainda não possuem geradores específicos validados; não selecione esses modos até uma versão posterior concluir essa implementação.
