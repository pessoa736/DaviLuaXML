# DLSX - Davi System Lua-XML

Um interpretador JSX-like para lua.

⚠️ Projeto experimental. APIs podem mudar sem aviso.

(Depois clocar imagem)

## sobre o que se trata o DSLX?

DSLX (ou Davi System: lua XML) é um módulo fornece ao lua a capacidade de interpretar arquivos .dslx no qual permite executar o código lua e transformar o xml em lua puro num mesmo arquivo, igual o JSX.

## qual o seu objetivo?

Fazer uma linguagem JSX-like para lua, com a melhor eficiência, performance, e que for possível, usando apenas lua puro. 

## status do projeto

O projeto está em estado experimental, mesmo com uma base da estrutura bem sólida, muitas APIs e muitos conceitos podem mudar a qualquer momento. E bugs são esperados.

## como funciona?

### sintaxe

No .dslx qualquer função definida no ambiente do lua pode ser chamada no formato do XML.

```lua

-- definindo em lua
function teste(props)
    local arg1, children = props.arg1, props.children
    
    return arg1 + (children or 0)
end

-- chamando em xml
local res = <teste arg1={1}> {2} </teste>;
print(res) -- isso retornara para o usuario: 3 

-- chamando self-close
print(<teste arg1={2}/>) -- isso mostra pro usuario: 2

```

### importação dos .dslx através do require

Quando seu projeto importa o módulo do DSLX ele carregar o loader do DSLX, sobreponto o require, permitindo importar o .dslx da mesma forma do .lua

## licença

Esse módulo é MIT. Sinta-se livre para brincar e fazer o que quiser a sua fork desse projeto, mantendo os creditos :)

## contribuição

Qualquer um pode contribuir com o projeto. Ao encontrar qualquer problema/bug ou se tiver alguma ideia de implementação, pode abrir uma issues para relatar o problema ou fazer um fork com sua implementação.