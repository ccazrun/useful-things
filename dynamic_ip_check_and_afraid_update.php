<?php
  //variables
  $allowed_domains = array("[domain1]", ... , "[domainX]");
  $mykey = "[long_strong_and_random_key]";
  $urlbase = "https://sync.afraid.org/u/";
  $urltail = "/?content-type=json&address=";
  // rndv2 is the key from the console. 
  // if you are only supporting one domain, you could put it here as a variable.
  // or create an array with the keys and read that.
  // I chose to allow the key to be in the post submission.
  $debug = 0;

  $output = '{"result": "Invalid Request"}';
  if( $_SERVER["REQUEST_METHOD"] == "GET" ) {
    header('Content-Type: text/html; charset=utf-8');
    $output="<html><head><title>IP</title></head><body>Current IP Address: ". $_SERVER['REMOTE_ADDR'] ."</body></html>";
  }
  if( $_SERVER["REQUEST_METHOD"] == "POST" ) {
    header('Content-Type: application/json; charset=utf-8');
    //check if key matches
    if( strtolower($mykey) == strtolower($_POST["key"]) ) {

      if ( in_array($_POST["dom"],$allowed_domains) ) {
        //if dom is in the allowed domains, then start to process

        $address       = $_SERVER['REMOTE_ADDR'];

        if ( $_POST["bog"] == "1" ) {
          $address     = "[BOGON_IP]";
        }

        if ( $debug == 1  ) {
          $address     = isset($_POST["opt1"]) ? $_POST["opt1"] : "[BOGON_IP_2]" ;
        }
              
        $domain        = $_POST["dom"];
        $update_url    = $urlbase . $_POST["rndv2"] . $urltail . $address ;
        
      
        //send the curl request out and capture the json response
        $cURLworker = curl_init();
        curl_setopt($cURLworker, CURLOPT_URL, $update_url);
        curl_setopt($cURLworker, CURLOPT_RETURNTRANSFER, true);
        $request_return = curl_exec($cURLworker);
        $output = $request_return;
      
      }
    }
  }
  echo $output;
?>

