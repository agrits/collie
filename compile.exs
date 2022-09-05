alias Collie.{Reader, Parser, Transpiler}
"input.cll"
|> File.read!()
|> Reader.read_str
|> Parser.parse_forms
|> Transpiler.write_to_file
