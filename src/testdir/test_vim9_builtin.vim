" Test using builtin functions in the Vim9 script language.

source check.vim
source vim9.vim

" Test for passing too many or too few arguments to builtin functions
func Test_internalfunc_arg_error()
  let l =<< trim END
    def! FArgErr(): float
      return ceil(1.1, 2)
    enddef
    defcompile
  END
  call writefile(l, 'Xinvalidarg')
  call assert_fails('so Xinvalidarg', 'E118:', '', 1, 'FArgErr')
  let l =<< trim END
    def! FArgErr(): float
      return ceil()
    enddef
    defcompile
  END
  call writefile(l, 'Xinvalidarg')
  call assert_fails('so Xinvalidarg', 'E119:', '', 1, 'FArgErr')
  call delete('Xinvalidarg')
endfunc

" Test for builtin functions returning different types
func Test_InternalFuncRetType()
  let lines =<< trim END
    def RetFloat(): float
      return ceil(1.456)
    enddef

    def RetListAny(): list<any>
      return items({k: 'v'})
    enddef

    def RetListString(): list<string>
      return split('a:b:c', ':')
    enddef

    def RetListDictAny(): list<dict<any>>
      return getbufinfo()
    enddef

    def RetDictNumber(): dict<number>
      return wordcount()
    enddef

    def RetDictString(): dict<string>
      return environ()
    enddef
  END
  call writefile(lines, 'Xscript')
  source Xscript

  call RetFloat()->assert_equal(2.0)
  call RetListAny()->assert_equal([['k', 'v']])
  call RetListString()->assert_equal(['a', 'b', 'c'])
  call RetListDictAny()->assert_notequal([])
  call RetDictNumber()->assert_notequal({})
  call RetDictString()->assert_notequal({})
  call delete('Xscript')
endfunc

def Test_abs()
  assert_equal(0, abs(0))
  assert_equal(2, abs(-2))
  assert_equal(3, abs(3))
  CheckDefFailure(['abs("text")'], 'E1013: Argument 1: type mismatch, expected number but got string', 1)
  if has('float')
    assert_equal(0, abs(0))
    assert_equal(2.0, abs(-2.0))
    assert_equal(3.0, abs(3.0))
  endif
enddef

def Test_add_list()
  var l: list<number>  # defaults to empty list
  add(l, 9)
  assert_equal([9], l)

  var lines =<< trim END
      var l: list<number>
      add(l, "x")
  END
  CheckDefFailure(lines, 'E1012:', 2)

  lines =<< trim END
      var l: list<number> = test_null_list()
      add(l, 123)
  END
  CheckDefExecFailure(lines, 'E1130:', 2)
enddef

def Test_add_blob()
  var b1: blob = 0z12
  add(b1, 0x34)
  assert_equal(0z1234, b1)

  var b2: blob # defaults to empty blob
  add(b2, 0x67)
  assert_equal(0z67, b2)

  var lines =<< trim END
      var b: blob
      add(b, "x")
  END
  CheckDefFailure(lines, 'E1012:', 2)

  lines =<< trim END
      var b: blob = test_null_blob()
      add(b, 123)
  END
  CheckDefExecFailure(lines, 'E1131:', 2)
enddef

def Test_append()
  new
  setline(1, range(3))
  var res1: number = append(1, 'one')
  assert_equal(0, res1)
  var res2: bool = append(3, 'two')
  assert_equal(false, res2)
  assert_equal(['0', 'one', '1', 'two', '2'], getline(1, 6))
enddef

def Test_buflisted()
  var res: bool = buflisted('asdf')
  assert_equal(false, res)
enddef

def Test_bufname()
  split SomeFile
  bufname('%')->assert_equal('SomeFile')
  edit OtherFile
  bufname('#')->assert_equal('SomeFile')
  close
enddef

def Test_bufnr()
  var buf = bufnr()
  bufnr('%')->assert_equal(buf)

  buf = bufnr('Xdummy', true)
  buf->assert_notequal(-1)
  exe 'bwipe! ' .. buf
enddef

def Test_bufwinid()
  var origwin = win_getid()
  below split SomeFile
  var SomeFileID = win_getid()
  below split OtherFile
  below split SomeFile
  bufwinid('SomeFile')->assert_equal(SomeFileID)

  win_gotoid(origwin)
  only
  bwipe SomeFile
  bwipe OtherFile
enddef

def Test_call_call()
  var l = [3, 2, 1]
  call('reverse', [l])
  l->assert_equal([1, 2, 3])
enddef

def Test_char2nr()
  char2nr('あ', true)->assert_equal(12354)
enddef

def Test_col()
  new
  setline(1, 'asdf')
  col([1, '$'])->assert_equal(5)
enddef

def Test_copy_return_type()
  var l = copy([1, 2, 3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)

  var dl = deepcopy([1, 2, 3])
  res = 0
  for n in dl
    res += n
  endfor
  res->assert_equal(6)

  dl = deepcopy([1, 2, 3], true)
enddef

def Test_count()
  count('ABC ABC ABC', 'b', true)->assert_equal(3)
  count('ABC ABC ABC', 'b', false)->assert_equal(0)
enddef

def Test_cursor()
  new
  setline(1, range(4))
  cursor(2, 1)
  assert_equal(2, getcurpos()[1])
  cursor('$', 1)
  assert_equal(4, getcurpos()[1])

  var lines =<< trim END
    cursor('2', 1)
  END
  CheckDefExecAndScriptFailure(lines, 'E475:')
enddef

def Test_delete()
  var res: bool = delete('doesnotexist')
  assert_equal(true, res)
enddef

def Test_executable()
  assert_false(executable(""))
  assert_false(executable(test_null_string()))

  CheckDefExecFailure(['echo executable(123)'], 'E928:')
  CheckDefExecFailure(['echo executable(true)'], 'E928:')
enddef

def Test_exepath()
  CheckDefExecFailure(['echo exepath(true)'], 'E928:')
  CheckDefExecFailure(['echo exepath(v:null)'], 'E928:')
  CheckDefExecFailure(['echo exepath("")'], 'E1142:')
enddef

def Test_expand()
  split SomeFile
  expand('%', true, true)->assert_equal(['SomeFile'])
  close
enddef

def Test_extend_arg_types()
  assert_equal([1, 2, 3], extend([1, 2], [3]))
  assert_equal([3, 1, 2], extend([1, 2], [3], 0))
  assert_equal([1, 3, 2], extend([1, 2], [3], 1))
  assert_equal([1, 3, 2], extend([1, 2], [3], s:number_one))

  assert_equal({a: 1, b: 2, c: 3}, extend({a: 1, b: 2}, {c: 3}))
  assert_equal({a: 1, b: 4}, extend({a: 1, b: 2}, {b: 4}))
  assert_equal({a: 1, b: 2}, extend({a: 1, b: 2}, {b: 4}, 'keep'))
  assert_equal({a: 1, b: 2}, extend({a: 1, b: 2}, {b: 4}, s:string_keep))

  var res: list<dict<any>>
  extend(res, mapnew([1, 2], (_, v) => ({})))
  assert_equal([{}, {}], res)

  CheckDefFailure(['extend([1, 2], 3)'], 'E1013: Argument 2: type mismatch, expected list<number> but got number')
  CheckDefFailure(['extend([1, 2], ["x"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  CheckDefFailure(['extend([1, 2], [3], "x")'], 'E1013: Argument 3: type mismatch, expected number but got string')

  CheckDefFailure(['extend({a: 1}, 42)'], 'E1013: Argument 2: type mismatch, expected dict<number> but got number')
  CheckDefFailure(['extend({a: 1}, {b: "x"})'], 'E1013: Argument 2: type mismatch, expected dict<number> but got dict<string>')
  CheckDefFailure(['extend({a: 1}, {b: 2}, 1)'], 'E1013: Argument 3: type mismatch, expected string but got number')

  CheckDefFailure(['extend([1], ["b"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  CheckDefExecFailure(['extend([1], ["b", 1])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<any>')
enddef

def Test_extendnew()
  assert_equal([1, 2, 'a'], extendnew([1, 2], ['a']))
  assert_equal({one: 1, two: 'a'}, extendnew({one: 1}, {two: 'a'}))

  CheckDefFailure(['extendnew({a: 1}, 42)'], 'E1013: Argument 2: type mismatch, expected dict<number> but got number')
  CheckDefFailure(['extendnew({a: 1}, [42])'], 'E1013: Argument 2: type mismatch, expected dict<number> but got list<number>')
  CheckDefFailure(['extendnew([1, 2], "x")'], 'E1013: Argument 2: type mismatch, expected list<number> but got string')
  CheckDefFailure(['extendnew([1, 2], {x: 1})'], 'E1013: Argument 2: type mismatch, expected list<number> but got dict<number>')
enddef

def Test_extend_return_type()
  var l = extend([1, 2], [3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

func g:ExtendDict(d)
  call extend(a:d, #{xx: 'x'})
endfunc

def Test_extend_dict_item_type()
  var lines =<< trim END
       var d: dict<number> = {a: 1}
       extend(d, {b: 2})
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
       var d: dict<number> = {a: 1}
       extend(d, {b: 'x'})
  END
  CheckDefFailure(lines, 'E1013: Argument 2: type mismatch, expected dict<number> but got dict<string>', 2)
  CheckScriptFailure(['vim9script'] + lines, 'E1012:', 3)

  lines =<< trim END
       var d: dict<number> = {a: 1}
       g:ExtendDict(d)
  END
  CheckDefExecFailure(lines, 'E1012: Type mismatch; expected number but got string', 0)
  CheckScriptFailure(['vim9script'] + lines, 'E1012:', 1)
enddef

func g:ExtendList(l)
  call extend(a:l, ['x'])
endfunc

def Test_extend_list_item_type()
  var lines =<< trim END
       var l: list<number> = [1]
       extend(l, [2])
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
       var l: list<number> = [1]
       extend(l, ['x'])
  END
  CheckDefFailure(lines, 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>', 2)
  CheckScriptFailure(['vim9script'] + lines, 'E1012:', 3)

  lines =<< trim END
       var l: list<number> = [1]
       g:ExtendList(l)
  END
  CheckDefExecFailure(lines, 'E1012: Type mismatch; expected number but got string', 0)
  CheckScriptFailure(['vim9script'] + lines, 'E1012:', 1)
enddef

def Test_job_info_return_type()
  if has('job')
    job_start(&shell)
    var jobs = job_info()
    assert_equal('list<job>', typename(jobs))
    assert_equal('dict<any>', typename(job_info(jobs[0])))
    job_stop(jobs[0])
  endif
enddef

def Wrong_dict_key_type(items: list<number>): list<number>
  return filter(items, (_, val) => get({[val]: 1}, 'x'))
enddef

def Test_filereadable()
  assert_false(filereadable(""))
  assert_false(filereadable(test_null_string()))

  CheckDefExecFailure(['echo filereadable(123)'], 'E928:')
  CheckDefExecFailure(['echo filereadable(true)'], 'E928:')
enddef

def Test_filewritable()
  assert_false(filewritable(""))
  assert_false(filewritable(test_null_string()))

  CheckDefExecFailure(['echo filewritable(123)'], 'E928:')
  CheckDefExecFailure(['echo filewritable(true)'], 'E928:')
enddef

def Test_finddir()
  CheckDefExecFailure(['echo finddir(true)'], 'E928:')
  CheckDefExecFailure(['echo finddir(v:null)'], 'E928:')
  CheckDefExecFailure(['echo finddir("")'], 'E1142:')
enddef

def Test_findfile()
  CheckDefExecFailure(['echo findfile(true)'], 'E928:')
  CheckDefExecFailure(['echo findfile(v:null)'], 'E928:')
  CheckDefExecFailure(['echo findfile("")'], 'E1142:')
enddef

def Test_fnamemodify()
  CheckDefSuccess(['echo fnamemodify(test_null_string(), ":p")'])
  CheckDefSuccess(['echo fnamemodify("", ":p")'])
  CheckDefSuccess(['echo fnamemodify("file", test_null_string())'])
  CheckDefSuccess(['echo fnamemodify("file", "")'])

  CheckDefExecFailure(['echo fnamemodify(true, ":p")'], 'E928:')
  CheckDefExecFailure(['echo fnamemodify(v:null, ":p")'], 'E928:')
  CheckDefExecFailure(['echo fnamemodify("file", true)'], 'E928:')
enddef

def Test_filter_wrong_dict_key_type()
  assert_fails('Wrong_dict_key_type([1, 2, 3])', 'E1012:')
enddef

def Test_filter_return_type()
  var l = filter([1, 2, 3], () => 1)
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

def Test_filter_missing_argument()
  var dict = {aa: [1], ab: [2], ac: [3], de: [4]}
  var res = dict->filter((k) => k =~ 'a' && k !~ 'b')
  res->assert_equal({aa: [1], ac: [3]})
enddef

def Test_garbagecollect()
  garbagecollect(true)
enddef

def Test_getbufinfo()
  var bufinfo = getbufinfo(bufnr())
  getbufinfo('%')->assert_equal(bufinfo)

  edit Xtestfile1
  hide edit Xtestfile2
  hide enew
  getbufinfo({bufloaded: true, buflisted: true, bufmodified: false})
      ->len()->assert_equal(3)
  bwipe Xtestfile1 Xtestfile2
enddef

def Test_getbufline()
  e SomeFile
  var buf = bufnr()
  e #
  var lines = ['aaa', 'bbb', 'ccc']
  setbufline(buf, 1, lines)
  getbufline('#', 1, '$')->assert_equal(lines)
  getbufline(-1, '$', '$')->assert_equal([])
  getbufline(-1, 1, '$')->assert_equal([])

  bwipe!
enddef

def Test_getchangelist()
  new
  setline(1, 'some text')
  var changelist = bufnr()->getchangelist()
  getchangelist('%')->assert_equal(changelist)
  bwipe!
enddef

def Test_getchar()
  while getchar(0)
  endwhile
  getchar(true)->assert_equal(0)
enddef

def Test_getcompletion()
  set wildignore=*.vim,*~
  var l = getcompletion('run', 'file', true)
  l->assert_equal([])
  set wildignore&
enddef

def Test_getloclist_return_type()
  var l = getloclist(1)
  l->assert_equal([])

  var d = getloclist(1, {items: 0})
  d->assert_equal({items: []})
enddef

def Test_getfperm()
  assert_equal('', getfperm(""))
  assert_equal('', getfperm(test_null_string()))

  CheckDefExecFailure(['echo getfperm(true)'], 'E928:')
  CheckDefExecFailure(['echo getfperm(v:null)'], 'E928:')
enddef

def Test_getfsize()
  assert_equal(-1, getfsize(""))
  assert_equal(-1, getfsize(test_null_string()))

  CheckDefExecFailure(['echo getfsize(true)'], 'E928:')
  CheckDefExecFailure(['echo getfsize(v:null)'], 'E928:')
enddef

def Test_getftime()
  assert_equal(-1, getftime(""))
  assert_equal(-1, getftime(test_null_string()))

  CheckDefExecFailure(['echo getftime(true)'], 'E928:')
  CheckDefExecFailure(['echo getftime(v:null)'], 'E928:')
enddef

def Test_getftype()
  assert_equal('', getftype(""))
  assert_equal('', getftype(test_null_string()))

  CheckDefExecFailure(['echo getftype(true)'], 'E928:')
  CheckDefExecFailure(['echo getftype(v:null)'], 'E928:')
enddef

def Test_getqflist_return_type()
  var l = getqflist()
  l->assert_equal([])

  var d = getqflist({items: 0})
  d->assert_equal({items: []})
enddef

def Test_getreg()
  var lines = ['aaa', 'bbb', 'ccc']
  setreg('a', lines)
  getreg('a', true, true)->assert_equal(lines)
enddef

def Test_getreg_return_type()
  var s1: string = getreg('"')
  var s2: string = getreg('"', 1)
  var s3: list<string> = getreg('"', 1, 1)
enddef

def Test_glob()
  glob('runtest.vim', true, true, true)->assert_equal(['runtest.vim'])
enddef

def Test_globpath()
  globpath('.', 'runtest.vim', true, true, true)->assert_equal(['./runtest.vim'])
enddef

def Test_has()
  has('eval', true)->assert_equal(1)
enddef

def Test_hasmapto()
  hasmapto('foobar', 'i', true)->assert_equal(0)
  iabbrev foo foobar
  hasmapto('foobar', 'i', true)->assert_equal(1)
  iunabbrev foo
enddef

def Test_index()
  index(['a', 'b', 'a', 'B'], 'b', 2, true)->assert_equal(3)
enddef

let s:number_one = 1
let s:number_two = 2
let s:string_keep = 'keep'

def Test_insert()
  var l = insert([2, 1], 3)
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)

  assert_equal([1, 2, 3], insert([2, 3], 1))
  assert_equal([1, 2, 3], insert([2, 3], s:number_one))
  assert_equal([1, 2, 3], insert([1, 2], 3, 2))
  assert_equal([1, 2, 3], insert([1, 2], 3, s:number_two))
  assert_equal(['a', 'b', 'c'], insert(['b', 'c'], 'a'))
  assert_equal(0z1234, insert(0z34, 0x12))

  CheckDefFailure(['insert([2, 3], "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 1)
  CheckDefFailure(['insert([2, 3], 1, "x")'], 'E1013: Argument 3: type mismatch, expected number but got string', 1)
enddef

def Test_keys_return_type()
  const var: list<string> = {a: 1, b: 2}->keys()
  var->assert_equal(['a', 'b'])
enddef

def Test_list2str_str2list_utf8()
  var s = "\u3042\u3044"
  var l = [0x3042, 0x3044]
  str2list(s, true)->assert_equal(l)
  list2str(l, true)->assert_equal(s)
enddef

def SID(): number
  return expand('<SID>')
          ->matchstr('<SNR>\zs\d\+\ze_$')
          ->str2nr()
enddef

def Test_map_function_arg()
  var lines =<< trim END
      def MapOne(i: number, v: string): string
        return i .. ':' .. v
      enddef
      var l = ['a', 'b', 'c']
      map(l, MapOne)
      assert_equal(['0:a', '1:b', '2:c'], l)
  END
  CheckDefAndScriptSuccess(lines)
enddef

def Test_map_item_type()
  var lines =<< trim END
      var l = ['a', 'b', 'c']
      map(l, (k, v) => k .. '/' .. v )
      assert_equal(['0/a', '1/b', '2/c'], l)
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
    var l: list<number> = [0]
    echo map(l, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown>', 2)

  lines =<< trim END
    var l: list<number> = range(2)
    echo map(l, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown>', 2)

  lines =<< trim END
    var d: dict<number> = {key: 0}
    echo map(d, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown>', 2)
enddef

def Test_maparg()
  var lnum = str2nr(expand('<sflnum>'))
  map foo bar
  maparg('foo', '', false, true)->assert_equal({
        lnum: lnum + 1,
        script: 0,
        mode: ' ',
        silent: 0,
        noremap: 0,
        lhs: 'foo',
        lhsraw: 'foo',
        nowait: 0,
        expr: 0,
        sid: SID(),
        rhs: 'bar',
        buffer: 0})
  unmap foo
enddef

def Test_mapcheck()
  iabbrev foo foobar
  mapcheck('foo', 'i', true)->assert_equal('foobar')
  iunabbrev foo
enddef

def Test_maparg_mapset()
  nnoremap <F3> :echo "hit F3"<CR>
  var mapsave = maparg('<F3>', 'n', false, true)
  mapset('n', false, mapsave)

  nunmap <F3>
enddef

def Test_max()
  g:flag = true
  var l1: list<number> = g:flag
          ? [1, max([2, 3])]
          : [4, 5]
  assert_equal([1, 3], l1)

  g:flag = false
  var l2: list<number> = g:flag
          ? [1, max([2, 3])]
          : [4, 5]
  assert_equal([4, 5], l2)
enddef

def Test_min()
  g:flag = true
  var l1: list<number> = g:flag
          ? [1, min([2, 3])]
          : [4, 5]
  assert_equal([1, 2], l1)

  g:flag = false
  var l2: list<number> = g:flag
          ? [1, min([2, 3])]
          : [4, 5]
  assert_equal([4, 5], l2)
enddef

def Test_nr2char()
  nr2char(97, true)->assert_equal('a')
enddef

def Test_readdir()
   eval expand('sautest')->readdir((e) => e[0] !=# '.')
   eval expand('sautest')->readdirex((e) => e.name[0] !=# '.')
enddef

def Test_readblob()
  var blob = 0z12341234
  writefile(blob, 'Xreadblob')
  var read: blob = readblob('Xreadblob')
  assert_equal(blob, read)

  var lines =<< trim END
      var read: list<string> = readblob('Xreadblob')
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected list<string> but got blob', 1)
  delete('Xreadblob')
enddef

def Test_readfile()
  var text = ['aaa', 'bbb', 'ccc']
  writefile(text, 'Xreadfile')
  var read: list<string> = readfile('Xreadfile')
  assert_equal(text, read)

  var lines =<< trim END
      var read: dict<string> = readfile('Xreadfile')
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected dict<string> but got list<string>', 1)
  delete('Xreadfile')
enddef

def Test_remove_return_type()
  var l = remove({one: [1, 2], two: [3, 4]}, 'one')
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(3)
enddef

def Test_reverse_return_type()
  var l = reverse([1, 2, 3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

def Test_search()
  new
  setline(1, ['foo', 'bar'])
  var val = 0
  # skip expr returns boolean
  search('bar', 'W', 0, 0, () => val == 1)->assert_equal(2)
  :1
  search('bar', 'W', 0, 0, () => val == 0)->assert_equal(0)
  # skip expr returns number, only 0 and 1 are accepted
  :1
  search('bar', 'W', 0, 0, () => 0)->assert_equal(2)
  :1
  search('bar', 'W', 0, 0, () => 1)->assert_equal(0)
  assert_fails("search('bar', '', 0, 0, () => -1)", 'E1023:')
  assert_fails("search('bar', '', 0, 0, () => -1)", 'E1023:')
enddef

def Test_searchcount()
  new
  setline(1, "foo bar")
  :/foo
  searchcount({recompute: true})
      ->assert_equal({
          exact_match: 1,
          current: 1,
          total: 1,
          maxcount: 99,
          incomplete: 0})
  bwipe!
enddef

def Test_searchdecl()
  searchdecl('blah', true, true)->assert_equal(1)
enddef

def Test_setbufvar()
  setbufvar(bufnr('%'), '&syntax', 'vim')
  &syntax->assert_equal('vim')
  setbufvar(bufnr('%'), '&ts', 16)
  &ts->assert_equal(16)
  setbufvar(bufnr('%'), '&ai', true)
  &ai->assert_equal(true)
  setbufvar(bufnr('%'), '&ft', 'filetype')
  &ft->assert_equal('filetype')

  settabwinvar(1, 1, '&syntax', 'vam')
  &syntax->assert_equal('vam')
  settabwinvar(1, 1, '&ts', 15)
  &ts->assert_equal(15)
  setlocal ts=8
  settabwinvar(1, 1, '&list', false)
  &list->assert_equal(false)
  settabwinvar(1, 1, '&list', true)
  &list->assert_equal(true)
  setlocal list&

  setbufvar('%', 'myvar', 123)
  getbufvar('%', 'myvar')->assert_equal(123)
enddef

def Test_setloclist()
  var items = [{filename: '/tmp/file', lnum: 1, valid: true}]
  var what = {items: items}
  setqflist([], ' ', what)
  setloclist(0, [], ' ', what)
enddef

def Test_setreg()
  setreg('a', ['aaa', 'bbb', 'ccc'])
  var reginfo = getreginfo('a')
  setreg('a', reginfo)
  getreginfo('a')->assert_equal(reginfo)
enddef 

def Test_slice()
  assert_equal('12345', slice('012345', 1))
  assert_equal('123', slice('012345', 1, 4))
  assert_equal('1234', slice('012345', 1, -1))
  assert_equal('1', slice('012345', 1, -4))
  assert_equal('', slice('012345', 1, -5))
  assert_equal('', slice('012345', 1, -6))

  assert_equal([1, 2, 3, 4, 5], slice(range(6), 1))
  assert_equal([1, 2, 3], slice(range(6), 1, 4))
  assert_equal([1, 2, 3, 4], slice(range(6), 1, -1))
  assert_equal([1], slice(range(6), 1, -4))
  assert_equal([], slice(range(6), 1, -5))
  assert_equal([], slice(range(6), 1, -6))

  assert_equal(0z1122334455, slice(0z001122334455, 1))
  assert_equal(0z112233, slice(0z001122334455, 1, 4))
  assert_equal(0z11223344, slice(0z001122334455, 1, -1))
  assert_equal(0z11, slice(0z001122334455, 1, -4))
  assert_equal(0z, slice(0z001122334455, 1, -5))
  assert_equal(0z, slice(0z001122334455, 1, -6))
enddef

def Test_spellsuggest()
  if !has('spell')
    MissingFeature 'spell'
  else
    spellsuggest('marrch', 1, true)->assert_equal(['March'])
  endif
enddef

def Test_sort_return_type()
  var res: list<number>
  res = [1, 2, 3]->sort()
enddef

def Test_sort_argument()
  var lines =<< trim END
    var res = ['b', 'a', 'c']->sort('i')
    res->assert_equal(['a', 'b', 'c'])

    def Compare(a: number, b: number): number
      return a - b
    enddef
    var l = [3, 6, 7, 1, 8, 2, 4, 5]
    sort(l, Compare)
    assert_equal([1, 2, 3, 4, 5, 6, 7, 8], l)
  END
  CheckDefAndScriptSuccess(lines)
enddef

def Test_split()
  split('  aa  bb  ', '\W\+', true)->assert_equal(['', 'aa', 'bb', ''])
enddef

def Test_str2nr()
  str2nr("1'000'000", 10, true)->assert_equal(1000000)

  CheckDefFailure(['echo str2nr(123)'], 'E1013:')
  CheckScriptFailure(['vim9script', 'echo str2nr(123)'], 'E1024:')
  CheckDefFailure(['echo str2nr("123", "x")'], 'E1013:')
  CheckScriptFailure(['vim9script', 'echo str2nr("123", "x")'], 'E1030:')
  CheckDefFailure(['echo str2nr("123", 10, "x")'], 'E1013:')
  CheckScriptFailure(['vim9script', 'echo str2nr("123", 10, "x")'], 'E1135:')
enddef

def Test_strchars()
  strchars("A\u20dd", true)->assert_equal(1)
enddef

def Test_submatch()
  var pat = 'A\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)'
  var Rep = () => range(10)->mapnew((_, v) => submatch(v, true))->string()
  var actual = substitute('A123456789', pat, Rep, '')
  var expected = "[['A123456789'], ['1'], ['2'], ['3'], ['4'], ['5'], ['6'], ['7'], ['8'], ['9']]"
  actual->assert_equal(expected)
enddef

def Test_synID()
  new
  setline(1, "text")
  synID(1, 1, true)->assert_equal(0)
  bwipe!
enddef

def Test_term_gettty()
  if !has('terminal')
    MissingFeature 'terminal'
  else
    var buf = Run_shell_in_terminal({})
    term_gettty(buf, true)->assert_notequal('')
    StopShellInTerminal(buf)
  endif
enddef

def Test_term_start()
  if !has('terminal')
    MissingFeature 'terminal'
  else
    botright new
    var winnr = winnr()
    term_start(&shell, {curwin: true})
    winnr()->assert_equal(winnr)
    bwipe!
  endif
enddef

def Test_timer_paused()
  var id = timer_start(50, () => 0)
  timer_pause(id, true)
  var info = timer_info(id)
  info[0]['paused']->assert_equal(1)
  timer_stop(id)
enddef

def Test_win_execute()
  assert_equal("\n" .. winnr(), win_execute(win_getid(), 'echo winnr()'))
  assert_equal('', win_execute(342343, 'echo winnr()'))
enddef

def Test_win_splitmove()
  split
  win_splitmove(1, 2, {vertical: true, rightbelow: true})
  close
enddef

def Test_winrestcmd()
  split
  var cmd = winrestcmd()
  wincmd _
  exe cmd
  assert_equal(cmd, winrestcmd())
  close
enddef

def Test_winsaveview()
  var view: dict<number> = winsaveview()

  var lines =<< trim END
      var view: list<number> = winsaveview()
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected list<number> but got dict<number>', 1)
enddef




" vim: ts=8 sw=2 sts=2 expandtab tw=80 fdm=marker
