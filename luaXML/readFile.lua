
--- Lê o conteúdo completo de um arquivo.
--- @param dirFile string Caminho do arquivo
--- @return string Conteúdo do arquivo
--- @error Se o arquivo não puder ser aberto
return function (dirFile)
    local file <close> = io.open(dirFile, "r+")
    if not file then
        error("não foi possivel abrir o arquivo: ".. dirFile)
    end

    local content = file:read("a")
    return content
end