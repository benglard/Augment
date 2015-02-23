<?php

session_start();

include_once 'classes/analysis.php';

if ($_FILES['userfile']['error']){
    echo json_encode(array('success' => 0, 'reason' => 'Sorry, file analysis failed, please try again.')); 
    exit();
}

$type = isset($_POST['type']) ? $_POST['type'] : 0
if ($type == 0) { 
    echo json_encode(array('success' => 0, 'reason' => 'Sorry, file analysis failed, please try again.')); 
    exit();
}

$is_url = isset($_POST['url']);
$url = $is_url ? $_POST['url'] : 0;

$paths = array();
$target_path = "uploads/";
if (mkdir($target_path));
else echo json_encode(array('success' => 0, 'reason' => 'Sorry, file analysis failed, please try again.'));

$c = 0;

if(! $is_url) {
    $name = $_FILES['video']['name'];
    $path = $target_path . basename($_FILES['video']['name']); 
    $url = "https://s3-us-west-2.amazonaws.com/project-augment/" . basename($_FILES['video']['name']);

    $success = true;
    if (move_uploaded_file($_FILES['video']['tmp_name'], $path)) {
        mkdir($target_path.'decoded/');
        $src = $path;
        $dst = $target_path.'decoded/' . basename( $_FILES['video']['name'] );
        base64file_decode( $src, $dst );
        $paths[$c] = $dst;
    } else { 
    	$success = false; 
    }

    $c += 1;
}

$name = $_FILES['picture']['name'];
$path = $target_path . basename($_FILES['picture']['name']);   
if (move_uploaded_file($_FILES['picture']['tmp_name'], $path)) {
    mkdir($target_path.'decoded/');
    $src = $path;
    $dst = $target_path.'decoded/' . basename( $_FILES['picture']['name'] );
    base64file_decode( $src, $dst );
    $paths[$c] = $dst;
}
else {
    $success = false;
}

if ($success == false) {
    echo json_encode(array('success' => 0, 'reason' => 'Sorry, file analysis failed, please try again.'));
} else {
    // start analysis in new file
    $_SESSION['isurl'] = $is_url;
    $_SESSION['paths'] = $paths;
    $_SESSION['url'] = $url;

    $Analysis = new analysis();
    $Analysis:init();
    echo json_encode(array('success' => boolval($Analysis::put_in_db())));
}

rmdir($target_path);

function base64file_decode( $inputfile, $outputfile ) { 
    /* read data (binary) */ 
    $ifp = fopen( $inputfile, "rb" ); 
    $srcData = fread( $ifp, filesize( $inputfile ) ); 
    fclose( $ifp ); 
    /* encode & write data (binary) */ 
    $ifp = fopen( $outputfile, "wb" ); 
    fwrite( $ifp, base64_decode( $srcData ) ); 
    fclose( $ifp ); 
    /* return output filename */ 
    return( $outputfile ); 
} 

function rmdir($dir) {
    array_map('unlink', glob($dir . "*"));
}

?>