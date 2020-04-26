#!/usr/bin/perl
#############################################################################
#
#	Script:		RPNtool.pl
#	Author:		Chris Vitalos
#	Description:	Using this script you can :
#			- Convert an Infix expression to Postfix
#			- Convert a Postfix expression to Infix
#			- Evaluate a Postfix expression
#			- Evaluate an Infix expression
#	Web:		  www.vitalos.us
#	E-mail:		cvitalos at yahoo dot com
#	Created:	23 April 2020
#
#	� 2020 Chris Vitalos. All rights reserved.
#
############################################################################

use strict;
use warnings;
use 5.10.0;

use Data::Dumper;
use Getopt::Std;

#
# sub isOperand
# returns a boolean if the input char is a math operand e.g. number
#

sub isOperand
{
	my ($who)=@_;
	if((!isOperator($who)) && ($who ne "(") && ($who ne ")") && !isFunction($who))
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#
# sub isOperator
# returns a boolean if the input char is a recognized math operator
#

sub isOperator
{
	my ($who)=@_;
	if(($who eq "+") || ($who eq "-") || ($who eq "*") || ($who eq "/") || ($who eq "^"))
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#
# sub isFunction
# returns a boolean if the input string is a recognized math function
#

sub isFunction
{
  my ($who)=@_;
  if(($who =~ /sin/i) || ($who =~ /cos/i) || ($who =~ /tan/i) || ($who =~ /sqrt/i) || ($who =~ /log/i) || ($who =~ /ln/i) || ($who =~ /exp/i))
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

#
# sub topStack
# essentially a stack peek() function
# returns the value at the top of the FILO stack
#

sub topStack
{
	my (@arr)=@_;
	my $arr_len=@arr;
	return($arr[$arr_len-1]);
}

#
# sub isEmpty
# returns boolean indicating if input list is empty (or not)
#

sub isEmpty
{
	my (@arr)=@_;
	my $arr_len=@arr;
	if(($arr_len)==0)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#
# sub prcd
# used to facilitate infix to RPN processing
# returns a priority assigned to an operator, or function
#

sub prcd
{
	my ($who)=@_;
	my $retVal;
	if($who eq "~")
	{
		$retVal="50";
	}
	elsif($who eq "^")
	{
	  $retVal="50";
	}
	elsif(($who eq "*") || ($who eq "/"))
	{
		$retVal="40";
	}
	elsif(($who eq "+") || ($who eq "-"))
	{
		$retVal="30";
	}
	elsif($who eq "(")
	{
		$retVal="20";
	}
	elsif(isFunction($who))
	{
		$retVal="20";
	}
	else
	{
		$retVal="10";
	}
	return($retVal);
}

#
# sub genArr
#
# this is the input string parser
# returns a list object of tokens
#

sub genArr
{
	my ($who)=@_;
	my @whoArr;
	my $i;
	my $temp;
	my $pc=0;
	my $l = length($who);
	
	$who=~tr/ //d;  #remove all whitespace from input string;
	
# 	say "Parsing $who";

	for($i=0; $i<=$l; $i++)
	{
	  $who=~m/\A\-{1}/;
	  if(defined($&))
	  {
	    if($i==0||($i>0&&!isOperand($whoArr[$i-1])))
	    {
	      $whoArr[$i]="~"
	    }
	    else
	    {
	      $whoArr[$i]="-";
	    }
	    $who=$';
	 # 	say "unary binary minus check: token=$whoArr[$i] remains=$who";
	    next;
	  }
		$who=~m/\A([0-9]+|\.)+/;
		if(defined($&))
		{
			$whoArr[$i]=$&;
			$who=$';
			if(defined($whoArr[$i-1]))
			{
			  if($whoArr[$i-1] eq "~")
			  {
			    $temp=$whoArr[$i-1]; $whoArr[$i-1]=$whoArr[$i]; $whoArr[$i]=$temp;
			  }
			}
		# 	say "numeral check: token=$whoArr[$i] remains=$who";
			next;
		}
		$who=~m/\A(\+|\*|\/|\^){1}/;
		if(defined($&))
		{
			$whoArr[$i]=$&;
			$who=$';
		# 	say "operator check: token=$whoArr[$i] remains=$who";
			next;
		}
		$who=~m/\A(\(|\)){1}/;
		if(defined($&))
		{
			$whoArr[$i]=$&;
			$who=$';
			$pc++ if ($& eq "(");  $pc-- if ($& eq ")");
		# 	say "parenthesis check: token=$whoArr[$i] remains=$who";
			next;
		}
		$who=~m/\A[A-Z|a-z]+\(/;
		if(defined($&))
		{
			$whoArr[$i]=$&; $whoArr[$i]=~tr/\($//d;
			$who=$'; $pc++;
		  die "Unrecognized function $&" if (!isFunction($&));
		# 	say "function check: token=$whoArr[$i] remains=$who";
			next;
		}
	}
	die "Unbalanced parentheses in input string!" if ($pc != 0);
# 	say Dumper @whoArr;
# 	say "Done";
	return(@whoArr);
}

#
# sub InfixToPostfix
#
# this performs the Shunting Yard Algorithm on input infix math string
# returns a list object representing a RPN (postfix) math expression
#

sub InfixToPostfix
{
	my ($infixStr)=@_;
	my @infixArr=genArr($infixStr);
	my @postfixArr;
	my @stackArr;
	my $postfixPtr=0;
	my $i;
	
# 	return ();   # Uncomment to debug parser sub genArr
	
	for($i=0; $i<scalar(@infixArr); $i++)
	{
		if(isOperand($infixArr[$i]))
		{
			$postfixArr[$postfixPtr]=$infixArr[$i];
			$postfixPtr++;
		}
		if(isOperator($infixArr[$i]))
		{
			if($infixArr[$i] ne "^")
			{
				while((!isEmpty(@stackArr)) && (prcd($infixArr[$i])<=prcd(topStack(@stackArr))))
				{
					$postfixArr[$postfixPtr]=topStack(@stackArr);
					pop(@stackArr);
					$postfixPtr++;
				}
			}
			else
			{
				while((!isEmpty(@stackArr)) && (prcd($infixArr[$i])<prcd(topStack(@stackArr))))
				{
					$postfixArr[$postfixPtr]=topStack(@stackArr);
					pop(@stackArr);
					$postfixPtr++;
				}
			}
			push(@stackArr,$infixArr[$i]);
		}
		if($infixArr[$i] eq "(" || isFunction($infixArr[$i]))
		{
			push(@stackArr,$infixArr[$i]);
		}
		if($infixArr[$i] eq ")")
		{
			while(!isEmpty(@stackArr))
			{
			  last unless (topStack(@stackArr) ne "(");
				$postfixArr[$postfixPtr]=pop(@stackArr);
				$postfixPtr++;
			}
			pop(@stackArr);
		}
	}
	while(!isEmpty(@stackArr))
	{
		if(topStack(@stackArr) eq "(" )
		{
			pop(@stackArr)
		}
		else
		{
			my $temp=@postfixArr;
			$postfixArr[$temp]=pop(@stackArr);
		}
	}
	return(@postfixArr);
}

#
# the following are collection of RPN post fix to infix processing routines
# remains untested
#

sub PostfixToInfix
{
	my ($postfixStr)=@_;
	my @stackArr;
	my @postfixArr=genArr($postfixStr);
	my $i;
	my $temp;
	my $pushVal;
	say Dumper $postfixStr;
	for($i=0; $i<length($postfixStr); $i++)
	{
		if(isOperand($postfixArr[$i]))
		{
			push(@stackArr,$postfixArr[$i]);
		}
		else
		{
			$temp=topStack(@stackArr);
			pop(@stackArr);
			$pushVal=topStack(@stackArr).$postfixArr[$i].$temp;
			pop(@stackArr);
			push(@stackArr,$pushVal);
		}
	}
	return((@stackArr));
}

sub PostfixEval
{
	my ($postfixStr)=@_;
	my @stackArr;
	my @postfixArr=genArr($postfixStr);
	my $i;
	for($i=0; $i<length($postfixStr); $i++)
	{
		if(isOperand($postfixArr[$i]))
		{
			push(@stackArr,$postfixArr[$i]);
		}
		else
		{
			my $temp=topStack(@stackArr);
			pop(@stackArr);
			my $pushVal=PostfixSubEval(topStack(@stackArr),$temp,$postfixArr[$i]);
			pop(@stackArr);
			push(@stackArr,$pushVal);
		}
	}
	return(topStack(@stackArr));
}

sub PostfixSubEval
{
	my ($num1,$num2,$sym)=@_;
	my $returnVal;
	if($sym eq "+")
	{
		$returnVal=$num1+$num2;
	}
	if($sym eq "-")
	{
		$returnVal=$num1-$num2;
	}
	if($sym eq "*")
	{
		$returnVal=$num1*$num2;
	}
	if($sym eq "/")
	{
		$returnVal=$num1/$num2;
	}
	if($sym eq "^")
	{
		$returnVal=$num1**$num2;
	}
	return($returnVal);
}

sub joinArr
{
	my (@who)=@_;
	my $who_len=@who;
	my $retVal;
	my $i;
	for($i=0; $i<$who_len; $i++)
	{
		$retVal.=$who[$i];
	}
	return $retVal;
}

sub evalInfix
{
	my ($exp)=@_;
	return PostfixEval(joinArr(InfixToPostfix($exp)));
}

#
# sub printInfixtoPostfix
#
# pretty prints a RPN math expression given an input infix math expression
#

sub printInfixtoPostfix
{
   my (@result) = InfixToPostfix(@_);
   say join(" ",@result);
}

#
# sub printInfixtoPostfix
#

sub printHelp
{
  say "RPNtool.pl: math infix to RPN tool .. and back ..";
  say "Invoke as : RPNtool.pl -t -r infix_expression";
  say "                       -t                  (runs built in test cases)";
  say "                       -r infix_expression (convert to RPN expression)";
}

#
# sub testCase
#
# executes a test case given the input testString (math expression)
# compares the observed result against passed expected result
# (hardcoded for Infix to Postfix RPN testing)
# prints pass/fail, testString, observed result
#

sub testCase
{
	my ($testString, $expectedResult) = @_;
	my @observedResult=InfixToPostfix($testString);
	my $result = ($expectedResult eq join(" ",@observedResult)) ? "PASSED" : "FAILED";
	say "$result : testString=($testString) expectedResult = ( $expectedResult )  observedResults = ( @observedResult )";
}

#
# sub runTestCases
#
# this is a collection of test cases
#

sub runTestCases
{
	testCase( "1+2"                  , "1 2 +" );
	testCase( "1 + 2"                , "1 2 +" );
	testCase( "1*(2^(3+4))"          , "1 2 3 4 + ^ *" );
	testCase( "1*2^(3+4)"            , "1 2 3 4 + ^ *" );
	testCase( "sin(1+2^4)"           , "1 2 4 ^ + sin" );
	testCase( "1+sin(2*4)"           , "1 2 4 * sin +" );
	testCase( "1*cos(6^9)"           , "1 6 9 ^ cos *" );
	testCase( "1*cos(6^9)+sin(3/4)"  , "1 6 9 ^ cos * 3 4 / sin +" );
	testCase( "1/log(cos(2*3))"      , "1 2 3 * cos log /" );
	testCase( "-1*sin(-10)"          , "1 ~ 10 ~ sin *");
	testCase( "5-1"                  , "5 1 -");
	testCase( "-5.1*5.3"             , "5.1 ~ 5.3 *");
	testCase( "1.7-3.14"             , "1.7 3.14 -");
	testCase( "1.9^-2.73"            , "1.9 2.73 ~ ^");
	testCase( "cos(-14)"             , "14 ~ cos");
	testCase( "5*-1*cos(-30)"        , "5 1 ~ * 30 ~ cos *");
}

#
# sub main
#

sub main
{
  my %options=();
  getopts("hr:t", \%options);
	runTestCases if (defined($options{t}));
	printInfixtoPostfix($options{r}) if (defined($options{r}));
	printHelp if (defined($options{h}));
	exit 0;
}

main();