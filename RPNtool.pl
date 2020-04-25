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

sub isOperand
{
	my ($who)=@_;
	if((!isOperator($who)) && ($who ne "(") && ($who ne ")"))
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub isOperator
{
	my ($who)=@_;
	if(($who eq "+") || ($who eq "-") || ($who eq "*") || ($who eq "/") || ($who eq "^") || isFunction($who))
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub isFunction
{
  my ($who)=@_;
  if(($who =~ /sin/i) || ($who =~ /cos/i) || ($who =~ /tan/i) || ($who =~ /sqrt/i) || ($who =~ /log/i) || ($who =~ /ln/i))
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

sub topStack
{
	my (@arr)=@_;
	my $arr_len=@arr;
	return($arr[$arr_len-1]);
}

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

sub prcd
{
	my ($who)=@_;
	my $retVal;
	if($who eq "^")
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
		$retVal="15";
	}
	else
	{
		$retVal="10";
	}
	return($retVal);
}

sub genArr
{
	my ($who)=@_;
	my @whoArr;
	my $i;
	my $l = length($who);
	#say "Parsing $who";
	for($i=0; $i<=$l; $i++)
	{
		$who=~m/\A([0-9]|\+|\-|\*|\/|\^|\(|\)){1}/;
		if(defined($&))
		{
			$whoArr[$i]=$&;
			$who=$';
			#say "non alpha check: token=$whoArr[$i] remains=$who";
			next;
		}
		$who=~m/\A[A-Z|a-z]+/;
		if(defined($&))
		{
			$whoArr[$i]=$&;
			$who=$';
			#say "alpha check: token=$whoArr[$i] remains=$who";
			next;
		}		
	} 
	#say Dumper @whoArr;
	#say "Done";
	return(@whoArr);
}

sub InfixToPostfix
{
	my ($infixStr)=@_;
	my @infixArr=genArr($infixStr);
	my @postfixArr;
	my @stackArr;
	my $postfixPtr=0;
	my $i;
	for($i=0; $i<scalar(@infixArr); $i++)
	{
		if(isOperand($infixArr[$i]))
		{
			$postfixArr[$postfixPtr]=$infixArr[$i];
			$postfixPtr++;
		}
		if(isOperator($infixArr[$i]))
		{
			if($infixArr[$i] ne "^" || !isFunction($infixArr[$i]))
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
		if($infixArr[$i] eq "(")
		{
			push(@stackArr,$infixArr[$i])
		}
		if($infixArr[$i] eq ")")
		{
			while(topStack(@stackArr) ne "(")
			{
				$postfixArr[$postfixPtr]=pop(@stackArr);
				$postfixPtr++;
			}
			pop(@stackArr);
		}
	}
	while(!isEmpty(@stackArr))
	{
		if(topStack(@stackArr) eq "(")
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

sub printInfixtoPostfix
{
   my (@result) = InfixToPostfix(@_);
   say "My Test string is @_";
   say "My Result is:";
   say Dumper @result;
  
}

sub testCase
{
	my ($testString, @expectedResult) = @_;
	my @observedResult=InfixToPostfix($testString);
	my $result = (join(";",@expectedResult) eq join(";",@observedResult)) ? "PASSED" : "FAILED";
	say "$result : testString=($testString) expectedResult = ( @expectedResult )  observedResults = ( @observedResult )";
}

sub runTestCases
{
	testCase( ("1+2","1","2","+") );
	testCase( ("1*(2^(3+4))","1","2","3","4","+","^","*") );
	testCase( ("1*2^(3+4)","1","2","3","4","+","^","*") );
	testCase( ("sin(1+2^4)","1","2","4","^","+","sin") );
	testCase( ("1+sin(2*4)","1","2","4","*","sin","+") );
	testCase( ("1*cos(6^9)","1","6","9","^","cos","*") );
	testCase( ("1*cos(6^9)+sin(3/4)","1","6","9","^","cos","*","3","4","/","sin","+") );
	#printInfixtoPostfix("1/log(cos(2*3))");   this case produces an infinite loop
}

sub main
{
	runTestCases;
	#printInfixtoPostfix(@ARGV);
	exit 0;
}

main;