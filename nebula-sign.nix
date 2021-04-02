{ pkgs, caCertFiles, ip, name } :
let
  keyPub = pkgs.runCommandNoCC "nebula-keypub" {
    inherit caCertFiles ip name;
    buildInputs = [ pkgs.nebula ];
  } ''
    mkdir $out
    nebula-cert sign -ca-crt $caCertFiles/ca.crt -ca-key $caCertFiles/ca.key \
                     -out-crt $out/$name.crt -out-key $out/$name.key       \
                     -ip $ip -name $name
  '';
in
{
  key = keyPub + "/${name}.key";
  crt = keyPub + "/${name}.crt";
}
