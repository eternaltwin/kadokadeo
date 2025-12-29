package externs;

@:js.import('jsencrypt', 'JSEncrypt')
extern class JSEncrypt {
    public function new();
    public function setPublicKey(key:String):Void;
    public function encrypt(data:String):String;
}
