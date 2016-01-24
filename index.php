<?php

/* This API was written for IT Assist Team 
   www.itassistteam.com
   
   This API uses the Slim framework(http://www.slimframework.com/) as a basis using composer
   to manage dependencies.
   
   This also uses a custom PDO management library that is not included as it is not currently open
   for public use.  You will need to replace it where necessary with your own library.
   
   With this library you can specify an array at the end of each route containing string values
   that specify which group a user must be a part of or leave it blank if it only requires authentication.
   For example at the end of a route add ->add(new CheckLogin()); for no groups or add(new CheckLogin(array("Admin")));
   to require the administrative group.

*/


session_start();
use \Psr\Http\Message\ServerRequestInterface as Request;
use \Psr\Http\Message\ResponseInterface as Response;

/**
 * Step 1: Require the Slim Framework using Composer's autoloader
 *
 * If you are not using Composer, you need to load Slim Framework with your own
 * PSR-4 autoloader.
 */

require 'vendor/autoload.php';

/*  This was a library built to use a static database configuration in /library
*   It uses PHP PDO library as a basis.
*/
require 'library/DBLib.php';
require 'library/LDapConfig.php';

/**
 * Step 2: Instantiate a Slim application
 *
 * This example instantiates a Slim application using
 * its default settings. However, you will usually configure
 * your Slim application now by passing an associative array
 * of setting names and values into the application constructor.
 */


$app = new \Slim\App;


/**
 * Step 3: Define the Slim application routes
 *
 * Here we define several Slim application routes that respond
 * to appropriate HTTP request methods. In this example, the second
 * argument for `Slim::get`, `Slim::post`, `Slim::put`, `Slim::patch`, and `Slim::delete`
 * is an anonymous function.
 */
 
 
/**
 * CheckLogin Class
 * Class verifies user has a session and a valid session ID
 * Class accepts on creation an array of groups and verifies
 * user is member of at least one group.  
 * Reports 401 if either condition fails
 * Passes back to next function in route if conditions pass
 */
 
class CheckLogin
{
 
   private $GroupsCheck = array();

   public function __construct($groups) {
	   $this->GroupsCheck = $groups;	   
   }

    /**
     * __invoke middleware invokable class
     *
     * @param  \Psr\Http\Message\ServerRequestInterface $request  PSR7 request
     * @param  \Psr\Http\Message\ResponseInterface      $response PSR7 response
     * @param  callable                                 $next     Next middleware
     * @classV array 									$GroupCheck    Groups
     * @return \Psr\Http\Message\ResponseInterface
     */
    public function __invoke($request, $response, $next)
    {
       	//Check if session login_id is set.  This is set in the /login route
		if(isset($_SESSION["login_id"])) {
			$query = "CALL CheckLogin(:loginid);";
			$params = array(
				":loginid" => $_SESSION["login_id"]
			);
			
			$results = DBLib::GetRow($query, $params);
			$groups =  json_decode($results['aResultData']['UserGroups']);
			if($results['bSuccess'] == false || !isset($results['aResultData']['LoginID'])){
				$newResponse = $response->withStatus(401);
				$newResponse->getBody()->write('Requires Authentication1');
				return $newResponse;
			}
			
		
			
			//If group array exists, check to see if user is part of any of the required groups
			if(!empty($this->GroupsCheck)){
				$InGroup = false;
				
				foreach($groups as $key => $v){
					if(in_array($v,$this->GroupsCheck)){
						$InGroup = true;
					}
				}
				// User not in group associated with this route
				if(!$InGroup){
					$newResponse = $response->withStatus(401);
					$newResponse->getBody()->write('Requires Group Membership');
					return $newResponse;
				}
			}
		}else{
			//No login_id present
			$newResponse = $response->withStatus(401);
		    $newResponse->getBody()->write('Requires Authentication');
			return $newResponse;
			
		}
	//If all checks have passed, move on to next routing function or middleware
    $response = $next($request, $response);
    return $response;
    }
}
 
 

/** 
 * LOGIN route
 * Handles user login using LDAP protocols
 * stores login_id in session variable to be used for future checks
 * stores user in database, phone # as extension and groups to be compared as needed
 * stores user name in database associated with user on first login
 */
$app->post('/login', function (Request $request, Response $response) {
	
	$response = $response->withHeader('Content-type', 'application/json');
	//Use what you put before username on login example\username
	$domainshort = LDapConfig::$domainshort;
	//full domain name (domain.local)
	$domainlong = LDapConfig::$domainlong;
	
    $allPostPutVars = $request->getParsedBody();

    $adServer = $domainlong;
	
	//instance LDap adapter
    $ldap = ldap_connect($adServer);
    $username = $allPostPutVars['username'];
    $password = $allPostPutVars['password'];
	
    $ldaprdn = $domainshort . "\\" . $username;

    ldap_set_option($ldap, LDAP_OPT_PROTOCOL_VERSION, 3);
    ldap_set_option($ldap, LDAP_OPT_REFERRALS, 0);

    $bind = @ldap_bind($ldap, $ldaprdn, $password);
	
	

	try{
		//check if successfully bound ldap protocol
		if ($bind) {
			$filter="(sAMAccountName=$username)";
			$result = ldap_search($ldap,"dc=" . LDapConfig::$domain2ndlevel . ",dc=" . LDapConfig::$domain1stlevel,$filter);
			ldap_sort($ldap,$result,"sn");
			$info = ldap_get_entries($ldap, $result);
			for ($i=0; $i<$info["count"]; $i++)
			{
				if($info['count'] > 1)
					break;
				
				$groupArray = array();	

				//check if member of any group, and add to login details
				if(isset($info[0]['memberof'])){
					for($e = 0; $e < $info[0]['memberof']['count']; $e++){
						$start = "="; 
						$end = ",";
					
						$string = ' ' . $info[0]['memberof'][$e];
						$ini = strpos($string, $start);
						if ($ini == 0) return '';
						$ini += strlen($start);
						$len = strpos($string, $end, $ini) - $ini;
						
						array_push($groupArray, substr($string, $ini, $len));
					}
				}
				$extension = "";
				if(isset($info[0]['telephonenumber'][0])){
					$extension = $info[0]['telephonenumber'][0];
				}
				
				$query = "CALL CheckUser(:username, :firstname, :lastname, :usergroups, :extension);";
				$params = array(
					":username" => $username,
					":firstname" => $info[0]['givenname'][0],
					":lastname" => $info[0]['sn'][0],
					":usergroups" => json_encode($groupArray),
					":extension" => $extension
				);
				
				$results = DBLib::GetRowAssoc($query, $params);
				
				
				if(!empty(LDapConfig::$AvailableGroups)){
					$InGroup = false;
					
					foreach($groupArray as $key => $v){
						if(in_array($v,LDapConfig::$AvailableGroups)){
							$InGroup = true;
							
						}
					}
					
					if(!$InGroup){
						$response->getBody()->write("{ 'bSuccess' : false, 'sErrorMsg' : 'User Not in group.  Please check with your administrator to have your login added to group $groupName, on domain $domainshort'}");
					}else{
						$_SESSION["login_id"] =  $results['aResultData']['loginid'];
						$response->getBody()->write(json_encode($results));
					}
				
				}else{
					
					$_SESSION["login_id"] =  $results['aResultData']['loginid'];
			
					$response->getBody()->write(json_encode($results));
				}

			}
			@ldap_close($ldap);
		} else {
			  $response->getBody()->write("{ 'bSuccess' : false, 'sErrorMsg' : 'Invalid email address / password' }");
		}
		
		}catch(Exception $e){
			   $response->getBody()->write("{ 'bSuccess' : false, 'sErrorMsg' : 'Invalid email address / password' }");
		}
	
	return $response; 
});


//verifies that the user is still logged in by utilizying the login handler
$app->get('/CheckLogin', function (Request $request, Response $response) {
	   echo '{"bSuccess" : true }';
}
)->add(new CheckLogin());

/**
 * Step 4: Run the Slim application
 *
 * This method should be called last. This executes the Slim application
 * and returns the HTTP response to the HTTP client.
 */
$app->run();
