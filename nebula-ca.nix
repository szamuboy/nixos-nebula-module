{ pkgs, name } :
let
  keyPub = pkgs.runCommandNoCC "nebula-keypub" {
    inherit name;
    buildInputs = [ pkgs.nebula ];
  } ''
    mkdir $out
    nebula-cert ca -name $name -out-crt $out/ca.crt -out-key $out/ca.key
  '';
in
{
  key = keyPub + "/ca.key";
  crt = keyPub + "/ca.crt";
}
