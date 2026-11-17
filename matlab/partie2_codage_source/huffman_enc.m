function bits = huffman_enc(x, symb, code)
%HUFFMAN_ENC  Codage de Huffman d'une séquence.
%   bits = huffman_enc(x, symb, code)
%   x    : séquence à coder
%   symb : alphabet (symb(i) est codé par code{i})
%   bits : vecteur ligne logique (true = 1)
[ok, idx] = ismember(x(:), symb);
if ~all(ok)
    error('huffman_enc:symbole', 'Symbole absent de l''alphabet du code.');
end
bits = [code{idx}] == '1';              % concaténation des mots de code
end
