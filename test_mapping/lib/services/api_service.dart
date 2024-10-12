import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

import '../config/config.dart';

class Methods {
  Future<http.Response> get(var accessToken, var apiEndPoint, var refreshFunction) async {
    if(!isTokenExpired(accessToken)){
      Uri url = Uri.https(Config.apiURL, apiEndPoint);
      final response = await http.get(
        Uri.https(Config.apiURL, apiEndPoint),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      print(response.statusCode);
      return response;
    }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return get(updatedAccessToken,apiEndPoint,refreshFunction);
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }
  }

  Future<http.Response> getWithParameters(var accessToken, var apiEndPoint, var queryParameters, var refreshFunction) async {
    if(!isTokenExpired(accessToken)){
      // Check if \$filter is null and handle it accordingly
      if (queryParameters.containsKey("\$filter") && queryParameters["\$filter"] != null) {
        // Replace spaces with %20 in the filter
        queryParameters["\$filter"] =
            queryParameters["\$filter"]!.replaceAll(' ', '%20');
      }

      Uri url = Uri.https(Config.apiURL, apiEndPoint, queryParameters);
      print('urlll $url');

      // Replace %2520 with %20
      String updatedUrl = url.toString().replaceAll('%2520', '%20');
      print('Updated url $updatedUrl');

      final response = await http.get(
        Uri.parse(updatedUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print(response.statusCode);
      return response;
    }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return getWithParameters(updatedAccessToken, apiEndPoint, queryParameters, refreshFunction);
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }


  }

  Future<http.Response> patch(var accessToken, var apiEndPoint, Map<String, dynamic> updateData,var eTag,var refreshFunction) async {
    if(!isTokenExpired(accessToken)){
    Uri url = Uri.https(Config.apiURL, apiEndPoint,{'odata-debug': 'json'});
    final response = await http.patch(
      Uri.https(Config.apiURL, apiEndPoint, {'odata-debug': 'json'}),
      headers: {
        'Content-Type': 'application/json;IEEE754Compatible=true',
        'Authorization': 'Bearer $accessToken',
        'If-Match': eTag
      },
      body: jsonEncode(updateData),
    );

    print("update Url $url");
    return response;
    }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return patch(updatedAccessToken, apiEndPoint,updateData,eTag,refreshFunction);
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }
  }

  Future<http.Response> post(var accessToken, var apiEndPoint, var eTag, var refreshFunction) async {
    if(!isTokenExpired(accessToken)){
      Uri url = Uri.https(Config.apiURL, apiEndPoint);
      print('url $url');
      final response = await http.post(
        Uri.https(Config.apiURL, apiEndPoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'If-Match': eTag
        },
        body: jsonEncode(<String, String>{}),
      );
      print('api service: Response code ${response.statusCode}');
      print(response.statusCode);
      return response;
    }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return post(updatedAccessToken, apiEndPoint, eTag, refreshFunction);
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }
  }

  Future<http.Response> postWithBody(var accessToken, var apiEndPoint, var eTag, Map<String, dynamic> requestBody,var refreshFunction) async {
    if (!isTokenExpired(accessToken)) {
      Uri url = Uri.https(Config.apiURL, apiEndPoint);
      final response = await http.post(
        Uri.https(Config.apiURL, apiEndPoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'If-Match': eTag
        },
        body: jsonEncode(requestBody),
      );
      return response;
    }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return postWithBody(updatedAccessToken, apiEndPoint, eTag, requestBody,refreshFunction);
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }
  }

  getImage(var accessToken, String luName, String keyRef,var refreshFunction) async {
    if (!isTokenExpired(accessToken)) {
      String apiEndPoint =
          "main/ifsapplications/projection/v1/MediaPanel.svc/GetOCTResultSet(LuName='$luName',KeyRef='$keyRef')";
      Uri url = Uri.https(Config.apiURL, apiEndPoint);
      final response = await http.get(
        Uri.https(Config.apiURL, apiEndPoint),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      print(response.statusCode);

      if (response.statusCode == 200) {
        var imageLink = jsonDecode(response.body);
        apiEndPoint =
        "main/ifsapplications/projection/v1/MediaLibraryManagerHandling.svc/MediaLibrarySet(LibraryId='${imageLink["value"][0]["LibraryId"]}')/LibraryItemDetailsArray(LibraryItemId=${imageLink["value"][0]["LibraryItemId"]},ItemId=${imageLink["value"][0]["ItemId"]},LibraryId='${imageLink["value"][0]["LibraryId"]}')/MediaItemArray(ItemId=1006)/MediaObject";
        Uri url = Uri.https(Config.apiURL, apiEndPoint);
        return Image.network(
          url.toString(),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      }
    }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return getImage(updatedAccessToken,luName, keyRef,refreshFunction);
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }
  }

  Future<http.Response> download(var accessToken, var apiEndPoint,var filename,var fileExt, docTitle, docClass, var refreshFunction ) async {
    if (!isTokenExpired(accessToken)) {
      Uri url = Uri.https(Config.apiURL, apiEndPoint); //call the url
      final response = await http.get(
        Uri.https(Config.apiURL, apiEndPoint),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
        saveFile(response.bodyBytes, filename, fileExt, docTitle,
            docClass); //save the file to device
        return response; //return the response
      }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return download(updatedAccessToken, apiEndPoint, filename, fileExt, docTitle, docClass, refreshFunction );
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }
  }

  Future<void> saveFile(Uint8List bodyBytes, filename,fileExt,docTitle,docClass) async {
    try {
      Directory appDocumentsDirectory = Directory("/storage/emulated/0/Download"); //set the download directory path
      String docname = docTitle+"_"+docClass+"_"+filename+"-"+DateTime.now().toString().replaceAll(':', '-'); //generate a unique name based on the file name
      String filePath = '${appDocumentsDirectory.path}/$docname.$fileExt'; //path to the file

      // Save the file to the device
      File file = File(filePath);
      await file.writeAsBytes(bodyBytes);

      // Show a notification or perform any action after successful save
      print('Saved to device: $docname.$fileExt');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<http.Response> postDoc(var accessToken, String apiEndPoint, Map<String, dynamic> requestBody, var refreshFunction) async {
    if (!isTokenExpired(accessToken)) {
      Uri url = Uri.https(Config.apiURL, apiEndPoint);
      final response = await http.post(
        Uri.https(Config.apiURL, apiEndPoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );
      return response;
    }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return postDoc(updatedAccessToken, apiEndPoint, requestBody, refreshFunction);
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }
  }

  Future<http.Response> uploadFile(var accessToken, docClass, docNo, docSheet, docRev, String luName, int taskSeq, List<int> file, fileName,var etag, var refreshFunction) async {
    if (!isTokenExpired(accessToken)) {
      //convert the fileName to base64
      String base64FileName = base64Encode(utf8.encode(fileName));
      String apiEndPoint = "main/ifsapplications/projection/v1/DocReferenceObjectAttachmentHandling.svc/DocReferenceObjectSet(DocClass='${docClass}',DocNo='${docNo}',DocSheet='${docSheet}',DocRev='${docRev}',LuName='$luName',KeyRef='TASK_SEQ=${taskSeq}^')/EdmFileReferenceArray(DocClass='${docClass}',DocNo='${docNo}',DocSheet='${docSheet}',DocRev='${docRev}',DocType='ORIGINAL',FileNo=1)/FileData";
      Uri url = Uri.https(Config.apiURL, apiEndPoint);
      print('url $url');
      final response = await http.patch(
          Uri.https(Config.apiURL, apiEndPoint),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Authorization': 'Bearer $accessToken',
            'If-Match': '*',
            'X-Ifs-Content-Disposition': 'filename=$base64FileName'
          },
          //convert the file to base64 and send it in the request body
          body: file
      );
      return response;
    }else{
      String updatedAccessToken = await refreshFunction();
      if(updatedAccessToken != 'unsuccessful'){
        return uploadFile(updatedAccessToken, docClass, docNo, docSheet, docRev, luName, taskSeq, file, fileName,etag, refreshFunction);
      }else{
        return http.Response('Token refresh failed', 401);
      }
    }
  }


  Future<http.Response> uploadMedia(var accessToken, List<int> file,itemId,fileName, var refreshFunction) async {
    if (!isTokenExpired(accessToken)) {
      //convert the fileName to base64
      String base64FileName = base64Encode(utf8.encode(fileName));
      print('base 64 file name : $base64FileName');
      String apiEndPoint = "main/ifsapplications/projection/v1/MediaLibraryAttachmentHandling.svc/MediaItemSet(ItemId=$itemId)/MediaObject";
      Uri url = Uri.https(Config.apiURL, apiEndPoint);
      print('url $url');
      final response = await http.patch(
          Uri.https(Config.apiURL, apiEndPoint),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Authorization': 'Bearer $accessToken',
            'If-Match': 'ETag here',
            'X-Ifs-Content-Disposition': 'filename=$base64FileName'
          },
          //convert the file to base64 and send it in the request body
          body: file
      );
      return response;
    }else{
      // String updatedAccessToken = await refreshFunction();
      // if(updatedAccessToken != 'unsuccessful'){
      //   // return uploadFile(updatedAccessToken, docClass, docNo, docSheet, docRev, luName, taskSeq, file, fileName,etag, refreshFunction);
      // }else{
      //   return http.Response('Token refresh failed', 401);
      // }
      return http.Response('Token refresh failed', 401);
    }
  }


  bool isTokenExpired(String accessToken){
    // bool expired = JwtDecoder.isExpired(accessToken);
    // print('expired status $expired');
    return JwtDecoder.isExpired(accessToken);
  }

}
