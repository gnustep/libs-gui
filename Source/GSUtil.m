/*
   GSUtil.m

   Some utility functions that are shared by several classes.


   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Pascal J. Bourguignon <pjb@imaginet.fr>
   Date: 2000-03-10
   Modifications: 
   Date: 

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/
#include "GSUtil.h"


    NSSize GSUtil_sizeOfMultilineStringWithFont(NSString* string,NSFont* font)
    {   
        static NSCharacterSet* newlines=nil;
        if(newlines==nil){
            // Let's build a character set containing only newline characters.
            NSMutableCharacterSet*  ms;
            NSCharacterSet*         whitespace;
            whitespace=[NSCharacterSet whitespaceCharacterSet];
            ms=[[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
            [ms formIntersectionWithCharacterSet:[whitespace invertedSet]];
            newlines=[ms copy];
            RELEASE(ms);
        }
        // TODO: Improve this method to split string by any char of newlines.
        {
            NSSize   result;
            NSArray* lines=[string componentsSeparatedByString:@"\n"];
            int lineCount=[lines count];
            int oneLineHeight=[font boundingRectForFont].size.height;
            switch(lineCount){
            case 0:
                result=NSMakeSize(0,oneLineHeight);
            case 1:
                result=NSMakeSize([font widthOfString:string],
                                  oneLineHeight);
            default:{
                    int maxWidth=0;
                    NSEnumerator* lineEnum=[lines objectEnumerator];
                    NSString* curLine;
                    while(0!=(curLine=[lineEnum nextObject])){
                        int width=[font widthOfString:curLine];
                        if(maxWidth<width){
                            maxWidth=width;
                        }
                    }
                    result=NSMakeSize(maxWidth,lineCount*oneLineHeight);
                }
            }//switch
            return(result);
        }
    }//GSUtil_sizeOfMultilineStringWithFont;


/*** GSUtil.m                         -- 2000-03-10 06:39:46 -- PJB ***/
