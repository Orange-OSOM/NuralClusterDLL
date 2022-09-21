#ifndef ParseC
#define ParseC

#include <iostream>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "parse.h"

namespace STE
{
	unsigned int parse::parseForQuant(const char* token, unsigned int tokelen, const char* sourse, unsigned int soursLen) {
		unsigned int tokenCharInd = 0;
		unsigned int quantity = 0;
		for (unsigned int i = 0; i < soursLen; i++)
		{
			if (sourse[i] == token[tokenCharInd])
			{
				tokenCharInd++;
				if (tokenCharInd == tokelen) {
					//end of corect word
					tokenCharInd = 0;
					quantity++;
				}
			}
			else {
				tokenCharInd = 0;
			}
		}
		return quantity;
	}

	unsigned int parse::parseForLoc(const char* token, unsigned int tokelen, const char* sourse, unsigned int soursLen) /*returns index of first chariter of token*/ {
		unsigned int tokenCharInd = 0;
		unsigned int posOfTok = 0;

		for (unsigned int i = 0; i < soursLen; i++)
		{

			if (sourse[i] == token[tokenCharInd]) {
				tokenCharInd++;
				if (tokenCharInd == tokelen) {
					//end of corect word
					posOfTok = i;
					i = soursLen;
				}
			}
			else {
				tokenCharInd = 0;
			}
		}
		//if (posOfTok - tokelen < 0) return soursLen;
		return posOfTok - tokelen;
	}

	char* parse::parseForLocPTR(const char* token, unsigned int tokelen, const char* sourse, unsigned int soursLen) {
		return (char*)(sourse + parseForLoc(token, tokelen, sourse, soursLen));
	}

	unsigned int parse::getUnsigned(const char* sourse, unsigned int soursLen) {
		unsigned int whiteSpaces = 0;
		unsigned int result = 0;
		//move past all non numarical chariters
		while (sourse[whiteSpaces] < '0' || sourse[whiteSpaces] > '9' && whiteSpaces < soursLen) {

			whiteSpaces++;
		}
		// translate the chariter limit to use less math in loop
		soursLen = soursLen - whiteSpaces;
		sourse = sourse + whiteSpaces;
		//loop to chariter limit or to end of number

		for (unsigned int i = 0; i < soursLen; i++)
		{
			if (sourse[i] >= '0' && sourse[i] <= '9')
			{
				result = (result * 10) + (sourse[i] - '0');
			}
			else
			{
				break;
			}
		}
		return result;
	}

	int getInt(char* sourse, unsigned int soursLen) {
		unsigned int whiteSpaces = 0;
		unsigned int result = 0;
		bool positive = true;
		//move past all non numarical chariters
		while (((sourse[whiteSpaces] < '0' && sourse[whiteSpaces] > '9') || (sourse[whiteSpaces] == '-')) && whiteSpaces < soursLen) {
			whiteSpaces++;
		}
		// translate the chariter limit to use less math in loop
		soursLen = soursLen - whiteSpaces;
		sourse = sourse + whiteSpaces;

		//loop to chariter limit or to end of number
		if (sourse[0] == '-') {
			whiteSpaces = 0;
			positive = false;
			while (sourse[whiteSpaces] < '0' && sourse[whiteSpaces] > '9' && whiteSpaces < soursLen) {
				{
					whiteSpaces++;
				}
				soursLen = soursLen - whiteSpaces;
				sourse = sourse + whiteSpaces;
			}

			for (unsigned int i = 0; i < soursLen; i++)
			{
				if (sourse[i] >= '0' && sourse[i] <= '9')
				{
					result = (result * 10) + (sourse[i] - '0');
				}
				else
				{
					break;
				}
			}
			if (!positive) {
				result = -1 * result;
			}
			return result;
		}

		/*float getFloat(char* sourse, unsigned int soursLen){}*/
	}

	
	
	/*
	__device__ unsigned int parseDev::parseForQuant(const char* token, unsigned int tokelen, const char* sourse, unsigned int soursLen) {
		unsigned int tokenCharInd = 0;
		unsigned int quantity = 0;
		for (unsigned int i = 0; i < soursLen; i++)
		{
			if (sourse[i] == token[tokenCharInd])
			{
				tokenCharInd++;
				if (tokenCharInd == tokelen) {
					//end of corect word
					tokenCharInd = 0;
					quantity++;
				}
			}
			else {
				tokenCharInd = 0;
			}
		}
		return quantity;
	}

	__device__ unsigned int parseDev::parseForLoc(const char* token, unsigned int tokelen, const char* sourse, unsigned int soursLen)  { //returns index of first chariter of token
		unsigned int tokenCharInd = 0;
		unsigned int posOfTok = 0;

		for (unsigned int i = 0; i < soursLen; i++)
		{

			if (sourse[i] == token[tokenCharInd]) {
				tokenCharInd++;
				if (tokenCharInd == tokelen) {
					//end of corect word
					posOfTok = i;
					i = soursLen;
				}
			}
			else {
				tokenCharInd = 0;
			}
		}
		return posOfTok - tokelen;
	}

	__device__ char* parseDev::parseForLocPTR(const char* token, unsigned int tokelen, const char* sourse, unsigned int soursLen) {
		return (char*)(sourse + parseForLoc(token, tokelen, sourse, soursLen));
	}

	__device__ unsigned int parseDev::getUnsigned(const char* sourse, unsigned int soursLen) {
		unsigned int whiteSpaces = 0;
		unsigned int result = 0;
		//move past all non numarical chariters
		while (sourse[whiteSpaces] < '0' || sourse[whiteSpaces] > '9' && whiteSpaces < soursLen) {

			whiteSpaces++;
		}
		// translate the chariter limit to use less math in loop
		soursLen = soursLen - whiteSpaces;
		sourse = sourse + whiteSpaces;
		//loop to chariter limit or to end of number

		for (unsigned int i = 0; i < soursLen; i++)
		{
			if (sourse[i] >= '0' && sourse[i] <= '9')
			{
				result = (result * 10) + (sourse[i] - '0');
			}
			else
			{
				break;
			}
		}
		return result;
	}
		
	__device__ int parseDev::getInt(const char* sourse, unsigned int soursLen) {
		unsigned int whiteSpaces = 0;
		unsigned int result = 0;
		bool positive = true;
		//move past all non numarical chariters
		while (((sourse[whiteSpaces] < '0' && sourse[whiteSpaces] > '9') || (sourse[whiteSpaces] == '-')) && whiteSpaces < soursLen) {
			whiteSpaces++;
		}
		// translate the chariter limit to use less math in loop
		soursLen = soursLen - whiteSpaces;
		sourse = sourse + whiteSpaces;

		//loop to chariter limit or to end of number
		if (sourse[0] == '-') {
			whiteSpaces = 0;
			positive = false;
			while (sourse[whiteSpaces] < '0' && sourse[whiteSpaces] > '9' && whiteSpaces < soursLen) {
				{
					whiteSpaces++;
				}
				soursLen = soursLen - whiteSpaces;
				sourse = sourse + whiteSpaces;
			}

			for (unsigned int i = 0; i < soursLen; i++)
			{
				if (sourse[i] >= '0' && sourse[i] <= '9')
				{
					result = (result * 10) + (sourse[i] - '0');
				}
				else
				{
					break;
				}
			}
			if (!positive) {
				result = -1 * result;
			}
			return result;
		}

		//float getFloat(char* sourse, unsigned int soursLen){}
	}

	__device__  int parseDev::testint() { return 0; }*/
}


namespace pog {

	__device__  int testin::testint() { return 0; }
}

#endif