" Author:  Iranoan <iranoan+vim@gmail.com>
" License: GPL Ver.3.

scriptversion 4
scriptencoding utf-8

if get(g:, 'loaded_autoload_asyncomplete_sources_mail')
	finish
endif
let g:loaded_autoload_asyncomplete_sources_mail = 1
let s:save_cpo = &cpoptions
set cpoptions&vim

execute 'py3file ' .. expand('<sfile>:p:h:h:h') .. '/asyncomplete-mail.py'

function asyncomplete#sources#mail#get_source_options(opts)
	return extend(extend({}, a:opts), {
				\ 'name': 'mail',
				\ 'completor': function('asyncomplete#sources#mail#completor'),
				\ 'refresh_pattern': '[^ ]\+$',
				\ 'triggers': {'*': ['/']},
				\ })
endfunction

function asyncomplete#sources#mail#completor(opt, ctx) abort
	let l:typed = a:ctx['typed']
	let l:col = a:ctx['col']
	let l:sync_name = synIDattr(synID(a:ctx['lnum'], l:col - 1, 0), 'name')
	if l:sync_name ==# 'mailHeaderEncrypt'
		let l:kw = matchstr(l:typed, '\m\c[a-z/-]\+$')
		let l:matches = s:comp_kw(l:kw, ['Subject', 'Public-Key', 'PublicKey'])
	elseif l:sync_name ==# 'mailHeaderSignature'
		let l:kw = matchstr(l:typed, '\m\c[a-z/-]\+$')
		let l:matches = s:comp_kw(l:kw, [])
	elseif l:sync_name ==# 'mailHeaderAttach'
		let l:kw = matchstr(matchstr(l:typed, '\m\c^Attach:\s*\zs[^ ]\+'), '[^ ]\+$')
		let l:matches = s:file(l:kw)
	" 以下は速度的な理由で Python 使用
	elseif l:sync_name ==# 'mailHeaderFcc'
		let l:kw = matchstr(matchstr(l:typed, '\m\c^Fcc:\s*\zs[^ ]\+'), '[^ ]\+$')
		let l:matches = map(py3eval('get_mail_folders()'), '{"word":v:val,"dup":0,"icase":1,"menu": "[Fcc]"}')
	elseif l:sync_name ==# 'mailHeaderAddress'
		let l:kw = matchstr(matchstr(l:typed, '\m^[^:]\+:\s*\zs.\+'), '\(\(\("\(\\"\|[^"]\)*"\|(\(\\(\|\\)\|[^()]\)*)\|[^,]\)\+\),\s*\)*\zs.\+$')
		let l:matches = py3eval('asyncomplete_address(''' .. substitute(substitute(l:kw, '\\', '\\\\', 'g'), '''', '\\\''', 'g') .. ''')')
	else
		return
	endif
	let l:kwlen = len(l:kw)
	let l:startcol = l:col - l:kwlen
	call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:matches)
endfunction

function s:comp_kw(kw, comp_ls)
	let l:matches = []
	for l:s in ['S/MIME', 'S-MIME', 'SMIME', 'PGP/MIME', 'PGP-MIME', 'PGPMIME', 'PGP'] + a:comp_ls
		if l:s =~# '\c' .. a:kw
			if l:s ==# 'S-MIME' || l:s ==# 'SMIME'
				let l:s = 'S/MIME'
			elseif l:s ==# 'PGP-MIME' || l:s ==# 'PGPMIME'
				let l:s = 'PGP/MIME'
			elseif l:s ==# 'PublicKey'
				let l:s = 'Public-Key'
			endif
			call add(l:matches, l:s)
		endif
	endfor
	if a:comp_ls == []
		return map(l:matches, '{"word":v:val,"dup":0,"icase":1,"menu": "[Signature]"}')
	else
		return map(l:matches, '{"word":v:val,"dup":0,"icase":1,"menu": "[Encrypt]"}')
	endif
endfunction

function s:filename_map(prefix, file) abort " https://github.com/prabirshrestha/asyncomplete-file.vim を参考にした
	let l:abbr = fnamemodify(a:file, ':t')
	let l:word = a:prefix .. l:abbr
	if isdirectory(a:file)
		let l:menu = '[dir]'
		let l:abbr = l:abbr.. '/'
	else
		let l:menu = '[file]'
		let l:abbr = l:abbr
	endif
	return {'menu': l:menu, 'word': l:word, 'abbr': l:abbr, 'icase': 1, 'dup': 0}
endfunction

function s:file(kw)
	if len(a:kw) < 1
		return []
	endif
	let l:file = s:get_wd()
	if a:kw !~# '^\(/\|\~\)'
		let l:cwd = l:file .. '/' .. a:kw
	else
		let l:cwd = a:kw
	endif
	let l:glob = fnamemodify(l:cwd, ':t') .. '.\=[^.]*'
	let l:cwd  = fnamemodify(l:cwd, ':p:h')
	let l:pre  = fnamemodify(a:kw, ':h')
	if l:pre !~# '^\(/\|\~\)' " 相対パスだとメール作成時と送信時でカレント・ディレクトリが異なると、別ファイル扱いになるのでフルパスか ~ で始まる形式にする
		let l:pre = simplify(l:file .. '/' .. l:pre)
	endif
	if l:pre !~# '/$'
		let l:pre = l:pre .. '/'
	endif
	let l:cwdlen   = strlen(l:cwd)
	let l:files    = split(globpath(l:cwd, l:glob), '\n')
	let l:matches  = map(l:files, {key, val -> s:filename_map(l:pre, val)})
	return sort(l:matches, function('s:sort'))
endfunction

function s:sort(item1, item2) abort
	if a:item1.word <? a:item2.word
		return -1
	elseif a:item1.word >? a:item2.word
		return 1
	elseif a:item1.menu ==# '[dir]' && a:item2.menu !=# '[dir]'
		return -1
	elseif a:item1.menu !=# '[dir]' && a:item2.menu ==# '[dir]'
		return 1
	endif
	return 0
endfunction

function s:get_wd() abort " working directory の取得
	if exists('g:notmuch_save_dir') " notmuch-py-vim の設定が有れば、その設定フォルダを
		return g:notmuch_save_dir
	endif
	for l:f in getbufinfo() " notmuch-py-vim を使っていれば、notmuch://folder? に従う
		let l:f = l:f['name']
		if l:f[:16] ==# 'notmuch://folder?'
					\ && get(swapinfo(l:f), 'error', '') ==# 'Cannot open file'
					\ && getftime(l:f) == -1
			return l:f[17:]
			break
		endif
	endfor
	" 以下単純に :pwd 相当
	let l:n = resolve(expand('%:p'))
	if getftype(l:n) == 'file'
		return fnamemodify(l:n, ':h')
	else
		return l:n
	endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
