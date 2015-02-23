<?php

session_start();
set_time_limit(600);

include_once 'S3.php';

class analysis {

    private static $is_url;
    private static $pic_path;
    private static $paths;
    private static $url;
    private static $threshold = 0.9;

    private static $link;
    private static $server = "localhost";
    private static $username = "root";
    private static $password = "root";
    private static $database_name = "augment";

    private static AWS_AKEY = "###";
    private static AWS_SKEY = "###";

    public static function init() {
    	self::$is_url = $_SESSION['isurl'];
    	self::$paths = $_SESSION['paths'];

    	$pic_path = "";
    	if (self::$is_url)
    		$pic_path = self::$paths[0];
    	else
    		$pic_path = self::$paths[1];
    	self::$pic_path = $pic_path;

    	self::$url = $_SESSION['url'];
    }

    public static function testConnection($getArray) {
        if ($getArray["test"] != "vjwosydhewkdlheubuozc")
            return False;
        return self::connect();
    }

    private static function query($str) {
        if (self::connect()) {
            $resource = mysqli_query(self::$link, $str);
            echo mysqli_error(self::$link);
            if ($resource) 
                return $resource;
            else 
                return False;
        }
        return False;
    }

    private static function getArrayQuery($str) {
        $result = self::query($str);
        $arr = Array();
        while ($tmp = mysqli_fetch_array($result))
            $arr[] = $tmp;
        echo mysqli_error(self::$link);
        return $arr;
    }

    public static function put_in_db() {
    	// Generate phash for image
    	// If url put phash, url else in db
    	// If video put video in S3, get url, put url else in db

    	$image = imagecreatefrompng(self::$pic_path);
    	$phash = implode(self::phash($image));
    	$type = "url";
    	
    	if (! self::$is_url) {
    		$type = "video";
    		$uploadFile = self::$paths[0];
    		$bucketName = "project-augment";

    		// Check if our upload file exists
    		if (!file_exists($uploadFile) || !is_file($uploadFile))
    			exit("\nERROR: No such file: $uploadFile\n\n");

    		// Check for CURL
    		if (!extension_loaded('curl') && !@dl(PHP_SHLIB_SUFFIX == 'so' ? 'curl.so' : 'php_curl.dll'))
    			exit("\nERROR: CURL extension not loaded\n\n");

    		// Instantiate the class
    		$s3 = new S3(self::$AWS_AKEY, self::$AWS_SKEY);

    		// Put our file (also with public read access)
    		$s3->putObjectFile($uploadFile, $bucketName, baseName($uploadFile), S3::ACL_PUBLIC_READ)
    	}

    	$insert = "INSERT INTO augment (phash, type, url) VALUES (\"$phash\", \"$type\", \"self::$url\")";
    	return self::query($insert);
    	}

    private static function phash($img) {
    	$w = imagesx($img);
        $h = imagesy($img);
        $r = $g = $b = 0;
        $pixels = array();
        for($y = 0; $y < $h; $y++) {
            for($x = 0; $x < $w; $x++) {
                $rgb = imagecolorat($img, $x, $y);
                $r = $rgb >> 16;
                $g = $rgb >> 8 & 255;
                $b = $rgb & 255;
                $gs = (($r*0.299)+($g*0.587)+($b*0.114));
                $gs = floor($gs);
                $pixels[] = $gs; 
            }
        }
        
        $avg = self::ArrayAverage($pixels);
        $hash = array();
        $index = 0;
        foreach($pixels as $px){
    		if ($px > $avg)
    			$hash[$index] = 1;
    		else
    			$hash[$index] = 0;
    		$index += 1;
    	}

    	for($c = 1; $c <= 3; $c += 1)
    		$hash = self::shorten($hash);

    	return $hash;
    }

    private static function ArrayAverage($arr) {
    	return floor(array_sum($arr) / count($arr));
    }

    private static function shorten($hash) {
    	$folded = array();
    	$size = count($hash);
    	for($i = 0; $i < $size/2; $i += 1) {
    		$one = $hash[$i];
    		$two = $hash[$size - $i - 1];
    		$folded[$i] = ($one + $two) / 2;
    	}
    	return $folded
    }

    private static function compare($hash1, $hash2, $precision = 1) {
    	$similarity = strlen($hash1);
    	for ($i=0; $i < strlen($hash1); $i += 1)
    		if ($hash1[$i] != $hash2[$i])
    			$similarity -= 1;
    	$percentage = round(($similarity/strlen($hash1)*100), $precision);
    	return $percentage;
    }
        
}

?>