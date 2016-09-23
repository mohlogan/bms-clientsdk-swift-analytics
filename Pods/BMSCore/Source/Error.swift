/*
*     Copyright 2016 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/



#if swift(>=3.0)
    
    
/**
    Indicates a failure that occurred within the BMSCore framework.
*/
public enum BMSCoreError: Error {
    
    case malformedUrl
    case clientNotInitialized
	case serverRespondedWithError
    
    static let domain = "com.ibm.mobilefirstplatform.clientsdk.swift.bmscore"
}
    
    
    
#else
    

/**
    Indicates a failure that occurred within the BMSCore framework.
*/
public enum BMSCoreError: Int, ErrorType {
    
    case malformedUrl
    case clientNotInitialized
    case serverRespondedWithError
    
    static let domain = "com.ibm.mobilefirstplatform.clientsdk.swift.bmscore"
}


#endif
