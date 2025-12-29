package kado;

typedef RunDTO = {
	var run_id:String;
	var server_time:Int;
	var contract_score:Int;
	var contract_points:Int;
	var seed:String;
};

typedef ApiResponse<T> = {
	data:T,
};

typedef EndRunRequestDTO = {
	var payload:String;
	var key:String;
	var sign:String;
}
