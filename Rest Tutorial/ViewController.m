//
//  ViewController.m
//  Rest Tutorial
//
//  Created by Larry Feldman on 6/24/15.
//  Copyright (c) 2015 Larry Feldman. All rights reserved.
//
//  StrikeIron Email Verification plus Hygiene

#import "ViewController.h"

#define kStrikeIronUserID   @"lfeldman65@gmail.com"
#define kStrikeIronPassword @"password"

@interface ViewController ()

- (IBAction)verifyEmail:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *emailAddress;
@property (weak, nonatomic) IBOutlet UILabel *verificationResults;
@property (copy, nonatomic) NSString *enteredEmailAddress;
@property (retain, nonatomic) NSMutableData *apiReturnXMLData;
@property NSURLConnection *currentConnection;
@property NSXMLParser *xmlParser;
@property (nonatomic) NSInteger statusNbr;
@property (copy, nonatomic) NSString *hygieneResult;
@property (copy, nonatomic) NSString *currentElement;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

}

- (BOOL)textFieldShouldReturn:(UITextField *)emailTextField {
    
    [emailTextField resignFirstResponder];
    return YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)verifyEmail:(id)sender {
    
    // store the value of the email address Text Field
    self.enteredEmailAddress = self.emailAddress.text;
    
    // Clear out the return message label
    self.verificationResults.text = @"";
    
    // Create the REST call string.
    NSString *restCallString = [NSString stringWithFormat:@"http://ws.strikeiron.com/StrikeIron/EMV6Hygiene/VerifyEmail?LicenseInfo.RegisteredUser.UserID=%@&LicenseInfo.RegisteredUser.Password=%@&VerifyEmail.Email=%@&VerifyEmail.Timeout=30", kStrikeIronUserID, kStrikeIronPassword, self.enteredEmailAddress ];
    
    // Create the URL to make the rest call.
    NSURL *restURL = [NSURL URLWithString:restCallString];
    NSURLRequest *restRequest = [NSURLRequest requestWithURL:restURL];
    
    // we will want to cancel any current connections
    if(self.currentConnection)
    {
        [self.currentConnection cancel];
        self.currentConnection = nil;
        self.apiReturnXMLData = nil;
    }
    
    self.currentConnection = [[NSURLConnection alloc] initWithRequest:restRequest delegate:self];
    
    // If the connection was successful, create the XML that will be returned.
    
    self.apiReturnXMLData = [NSMutableData data];

}

// didReceiveResponse is called when there is return data. It may be called multiple times for a connection and you should reset the data if it is.

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    [self.apiReturnXMLData setLength:0];
}


// didReceiveData is called when some or all of the data from the API call is returned. We will append the data to the apiReturnXMLData instance variable.

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.apiReturnXMLData appendData:data];
}

// didFailWithError is called when there is a terminal error. There will be no other method calls on this connection if it is received. In this case, we are just going to log the error.

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"URL Connection Failed!");
    self.currentConnection = nil;
}

// connectionDidFinishLoading method is called when the call is complete and all data has been received. Instantiate the parser, load it with the XML that was returned from the API call, set the delegate, and start it.

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
   
    // create our XML parser with the return data from the connection
    self.xmlParser = [[NSXMLParser alloc] initWithData:self.apiReturnXMLData];
    
    // setup the delgate (see methods below)
    
    [self.xmlParser setDelegate:self];
    
    // start parsing. The delgate methods will be called as it is iterating through the file.
    [self. xmlParser parse];
    
    self.currentConnection = nil;

}

/*  didStartElement is called each time an element tag is encountered. Once in an element, the charaters are passed to the foundCharaters method. didEndElement is called when the element tag is closed. Finally we will implement the parserDidEndDocument which is called when the document parsing is completed. We will first check and see if there is an error. If so, we will just print out a message and let the user continue the process. We will then check to see if the element is StatusNbr or HygieneResult. If so, we will set a instance variable to maintain state between the methods calls. It will indicate to the foundCharacters method which element we are currently in. */

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary *)attributeDict {
    
    // Log the error - in this case we are going to let the user pass but log the message
    if( [elementName isEqualToString:@"Error"])
    {
        NSLog(@"Web API Error!");
    }
    
    // Pull out the elements we care about.
    if( [elementName isEqualToString:@"StatusNbr"] ||
       [elementName isEqualToString:@"HygieneResult"])
    {
        self.currentElement = [[NSString alloc] initWithString:elementName];
    }
}

// Next we will implement the foundCharacters method. We will see if we are inside of the two elements that we care about. If so, we will set the appropriate instance variable and reset the currentElement instance variable.

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string {
    
    if([self.currentElement isEqualToString:@"StatusNbr"])
    {
        self.statusNbr = [string intValue];
        self.currentElement = nil;
    }
    else if([self.currentElement isEqualToString:@"HygieneResult"])
    {
        self.hygieneResult = [[NSString alloc] initWithString:string];
        self.currentElement = nil;
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
}

// Here we are going to add the logic to determine if the email is valid, invalid, or a trap. Then we will display the results in the label that is currently blank.

-(void)parserDidEndDocument:(NSXMLParser *)parser {
    
    // Determine what we are going to display in the label
    if([self.hygieneResult isEqualToString:@"Spam Trap"])
    {
        self.verificationResults.text = @"Dangerous email, please correct";
    }
    else if(self.statusNbr >= 300)
    {
        self.verificationResults.text = @"Invalid email, please re-enter";
    }
    else
    {
        self.verificationResults.text = @"Thank you for your submission";
    }
    
    self.apiReturnXMLData = nil;
}



@end
