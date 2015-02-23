<?php

session_start();

include_once 'classes/analysis.php';

$success = true;
$target_path = "uploads/";

$name = $_FILES['picture']['name'];
$path = $target_path . basename($_FILES['picture']['name']);   
if (move_uploaded_file($_FILES['picture']['tmp_name'], $path)) {
    mkdir($target_path.'decoded/');
    $src = $path;
    $dst = $target_path.'decoded/' . basename( $_FILES['picture']['name'] );
    base64file_decode( $src, $dst );
    $path = $dst;
} else { 
    $success = false;
}

if ($success == false) {
    echo json_encode(array('success' => 0, 'reason' => 'Sorry, analysis failed, please try again.'));
} else {
    // start analysis in new file
    $_SESSION['path'] = $path;

    $Analysis = new analysis();
    $Analysis:initDecode();
    $ret = $Analysis::get()
    echo json_encode(array('success' => $ret['success'], 
    					'url' ==> isset($ret['url']) ? $ret['url'] ? 0,
    					'type' ==> isset($ret['type']) ? $ret['type'] ? 0));
}

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