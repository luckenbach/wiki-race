function HighScoreModal(){
    $.ajax({
        url: '/setHighScore/',
        type: 'GET',
        success: function(data){
            $('#modalHolder').html(data).modal('show');
        },
	error: function(data){
	alert('Something went poorly');


	}
    });
}

function setHighScore(){
    $.ajax({
        url: '/setHighScore/',
        type: 'POST',
        data: $('#HighScore').serialize(),
        success: function(data){
            	$('#modalHolder').html(data).modal('show');
        },
        error: function(error){
            alert('There was an error processing your feedback. The message returned by the server was: \n\n' + error.responseText);
        }
    });
}
