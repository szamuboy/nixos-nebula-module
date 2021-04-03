{ pkgs, caCertFiles, ip, name } :
let
  keyPub = pkgs.runCommandNoCC "nebula-keypub" {
    inherit ip name;
    buildInputs = [ pkgs.nebula ];
    caCrt = caCertFiles.crt;
    caKey = caCertFiles.key;
  } ''
    mkdir $out
    nebula-cert sign -ca-crt $caCrt -ca-key $caKey \
                     -out-crt $out/$name.crt -out-key $out/$name.key       \
                     -ip $ip -name $name
  '';
in
{
  key = keyPub + "/${name}.key";
  crt = keyPub + "/${name}.crt";
}
