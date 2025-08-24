(function(window) {

    window["env"] = window["env"] || {};
      // var apiImageUrl = `${window.location.protocol}//${window.location.hostname}` + ":2083/";
      // window["env"]["apiUrl"] = `${window.location.protocol}//${window.location.hostname}` + ":2083/api/";
  
      // window["env"]["allowedDomains"] = [window.location.hostname +":2083"];

    var apiImageUrl = "https://crmbackend.kaankale.xyz/api/"
    window["env"]["apiUrl"] = "https://crmbackend.kaankale.xyz/api/";
  
    window["env"]["allowedDomains"] = ["https://crmbackend.kaankale.xyz/api/"];



    window["env"]["userImage"] = apiImageUrl + "Uploads/User/";
    window["env"]["employeeImage"] = apiImageUrl + "Uploads/Employee/";
    window["env"]["categoryImage"] = apiImageUrl + "Uploads/FoodCategory/";
    window["env"]["menuImage"] = apiImageUrl + "Uploads/Menu/";
    window["env"]["dutyImageBefore"] = apiImageUrl + "Uploads/BeforeCleaning/";
    window["env"]["dutyImageAfter"] = apiImageUrl + "Uploads/AfterCleaning/";
    window["env"]["technicalErrorImageBefore"] = apiImageUrl + "Uploads/TechnicalError/";
    window["env"]["propertyImage"] = apiImageUrl + "Uploads/LostProperty/";
    window["env"]["noImage"] = apiImageUrl + "Uploads/Images/noimage.jpg";
  })(this);


