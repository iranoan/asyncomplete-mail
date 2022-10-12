# asyncomplete-mail

## 概要

[notmuch-py-vim](https://github.com/iranoan/notmuch-py-vim) の下書きメールのヘッダで補完する

## 要件

### Vim

``` vim
$ vim --version | grep +python3
```

### [notmuch-py-vim](https://github.com/iranoan/notmuch-py-vim)

このプラグインの下書き (&|filetype|==notmuch-draft) 上での動作を想定している

これに準じて次が必要

* Notmuch
* Python Ver.3.5 以上

### [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim)

## あれば便利になるツール

### [GooBook](https://gitlab.com/goobook/goobook)

Google contacts をメール・アドレス簿として利用可能になる

Ubuntu 等の Debian 系なら

``` sh
$ sudo apt install -y goobook
```

他では例えば

``` sh
$ python3 -m pip install goobook
```

## インストール

使用しているパッケージ・マネージャに従えば良い

## [Vundle](https://github.com/gmarik/vundle)

``` vim
Plug 'iranoan/asyncomplete-mail'
```

## [Vim-Plug](https://github.com/junegunn/vim-plug)

``` vim
Plug 'iranoan/asyncomplete-mail'
```

## [NeoBundle](https://github.com/Shougo/neobundle.vim)

``` vim
NeoBundle 'iranoan/asyncomplete-mail'
```

## [dein.nvim](https://github.com/Shougo/dein.vim)

``` vim
call dein#add('iranoan/asyncomplete-mail')
```

## Vim packadd

``` sh
$ git clone https://github.com/iranoan/asyncomplete-mail ~/.vim/pack/iranoan/start/asyncomplete-mail
```

遅延読み込みをさせるなら

``` sh
$ git clone https://github.com/iranoan/asyncomplete-mail ~/.vim/pack/iranoan/opt/asyncomplete-mail
```

\~/.vim/vimrc などの設定ファイルに次のような記載を加える

``` vim
call asyncomplete#register_source(asyncomplete#sources#mail#get_source_options({
\ 'allowlist': ['notmuch-draft'],
\ }))
```

## 使用方法

上記のように `'allowlist': ['notmuch-draft']` が済んでいれば、メール・ヘッダー上
でインサート・モードなら補完が始まる

* From, To, Cc, Bcc 等ではメールアドレス
* Fcc ではメール・ボックス
* Attach では添付ファイル (ファイル・パス)

## TODO

notmuch-py-vim の使用を前提としているが、それ以外の環境での動作は希望者がいれ
ば改良する
