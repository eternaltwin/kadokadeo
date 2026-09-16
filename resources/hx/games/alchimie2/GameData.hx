package alchimie2;

typedef Artefact = {
	var id:ArtefactId;
	var freq:Int;
}

typedef GameData = {
	var mode:String;
	var chain:Array<ArtefactId>;
	var chWeight:Array<Int>;
	var artefacts:Array<Artefact>;
	var helps:Array<{id:ArtefactId, help:String}>;
}

enum ArtefactId {
	// éléments simples
	Elt(e:Int);
	// groupe d'éléments à jouer
	Elts(nb:Int, p:ArtefactId); // p parasit

	// artefacts
	Alchimoth;
	Dynamit(v:Int);
	PearGrain(level:Int);
	Grenade(level:Int);

	// auto falls
	Block(level:Int);
	Neutral;
}
