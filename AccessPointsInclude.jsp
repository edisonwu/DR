<%@ page contentType="text/html; charset=UTF-8" %>
<%@ taglib uri="/tlds/marketmaker.tld" prefix="dr" %>
<%@ taglib uri="/tlds/struts-bean.tld" prefix="bean" %>
<%@ taglib uri="/tlds/struts-logic.tld" prefix="logic" %>
<%@ taglib uri="/tlds/request.tld" prefix="req" %>
<%@ taglib uri="/tlds/string.tld" prefix="str" %>

<dr:page>
  <logic:if op="equal" name="page" property="currentPage" value="QuickBuyCartPage">
  <logic:or op="equal" name="page" property="currentPage" value="ThreePgCheckoutAddressPaymentInfoPage"/>
    <logic:then>
      <logic:present name="page" property="activeRequisition">
        <bean:define id="req" name="page" property="activeRequisition"/>
        <logic:equal name="req" property="shippingAddressRequired" value="true">
          <logic:equal name="req" property="accessPointShippingMethod" value="true">
            <bean:define id="isAuthenticated" name="page" property="userSession.authenticated"/>
            <dr:defineString id="mapCulture">
              <str:replace replace="_" with="-"><bean:write name="page" property="user.locale"/></str:replace>
            </dr:defineString>
            <dr:defineString id="mapControlPath">
              <dr:resource key="SiteSetting_BING_MAPS_MAP_CONTROL_PATH" param0="<%=mapCulture%>"/>
            </dr:defineString>
            <dr:defineString id="apSupportedCountries">
              <dr:resource key="SiteSetting_UPS_ACCESS_POINTS_SUPPORTED_COUNTRIES"/>
            </dr:defineString>
            <dr:defineString id="searchRadiusOptions">
              <dr:resource key="SiteSetting_SEARCH_RADIUS_OPTIONS"/>
            </dr:defineString>
   
            <dr:resource key="ACCESS_POINTS_CSS"/>

            <script type="text/javascript" src="<%=mapControlPath%>" async defer></script>

            <script>
              drAP = function() {
                var $shippingFields = $("#shippingCompanyName, #shippingAddress1, #shippingAddress2, #shippingCity, #shippingPostalCode");
                var $shippingSelect = $("#shippingState, #shippingCountry");
                var bootstrapEnabled = false;
                var map = null;
                var pinInfobox = null;

                function initMap() {
                  var bingMapsKey = '<dr:resource key="SiteSetting_BING_MAPS_KEY"/>';
                  var showMapTypeSelector = ('<dr:resource key="SiteSetting_BING_MAPS_SHOW_MAP_TYPE_SELECTOR"/>' == "true");

                  if ($("#dr_apMap .MicrosoftMap").length > 0) {
                    $("#dr_apMap .MicrosoftMap").remove();
                    map = null;
                  }

                  map = new Microsoft.Maps.Map("#dr_apMap", {
                    credentials: bingMapsKey,
                    mapTypeId: Microsoft.Maps.MapTypeId.road,
                    navigationBarMode: Microsoft.Maps.NavigationBarMode.compact,
                    showMapTypeSelector: showMapTypeSelector
                  });
                }

                function initPopup() {
                  var postalCode = $("#billingPostalCode").val();
                  var countryCode = $("#billingCountry").val();
                  var apCountryCode = $("#shippingCountry").val();
                  var apPostalCode = $("#shippingPostalCode").val();

                  if (apPostalCode != "") {
                    $("#dr_apCountry").val(apCountryCode);
                    $("#dr_apPostalCode").val(apPostalCode);
                  } else if (postalCode != "") {
                    $("#dr_apCountry").val(countryCode);
                    $("#dr_apPostalCode").val(postalCode);
                  } else {
                    $("#dr_apPostalCode").val("");
                  }

                  $("#dr_apInfo").empty();
                  $("#dr_apMakeBtn").prop("disabled", true);

                  if (bootstrapEnabled) {
                    $("#dr_apModal .dr_error").text("");
                  } else {
                    $("#dr_apContent span.dr_error").text("");
                  }

                  $("#dr_apBody").css("opacity", "1");
                }

                function constructPushpin(pinLayer, locs, LocationData) {
                  var pushpinOptions = {};
                  var pushpinColor = '<dr:resource key="SiteSetting_PUSHPIN_COLOR"/>';
                  var pushpinIcon = '<dr:resource key="SiteSetting_PUSHPIN_ICON"/>';
                  var pushpinHoverStyle = ('<dr:resource key="SiteSetting_PUSHPIN_HOVER_STYLE"/>' == "true");

                  if (pushpinColor != "PUSHPIN_COLOR") {
                    pushpinOptions = {color: pushpinColor};
                  } else if (pushpinIcon != "PUSHPIN_ICON") {
                    var anchorX = Number('<dr:resource key="SiteSetting_PUSHPIN_ANCHOR_X"/>');
                    var anchorY = Number('<dr:resource key="SiteSetting_PUSHPIN_ANCHOR_Y"/>');
                    
                    pushpinOptions = {icon: pushpinIcon, anchor: new Microsoft.Maps.Point(anchorX, anchorY)};
                  } else {
                    pushpinOptions = null;
                  }
                  
                  var loc = new Microsoft.Maps.Location(LocationData.Geocode.Latitude, LocationData.Geocode.Longitude);
                  var pushpin = new Microsoft.Maps.Pushpin(loc, pushpinOptions);

                  locs.push(loc);

                  var apTitle = LocationData.AddressKeyFormat.ConsigneeName;
                  var apAddressPostcode = LocationData.AddressKeyFormat.PostcodePrimaryLow;
                  var postcodeExtended = LocationData.AddressKeyFormat.PostcodeExtendedLow;

                  if (postcodeExtended) {
                    apAddressPostcode = apAddressPostcode + "-" + postcodeExtended;
                  }

                  var apAddressLine1 = LocationData.AddressKeyFormat.AddressLine;
                  var apAddressCity = LocationData.AddressKeyFormat.PoliticalDivision2;
                  var apAddressState = LocationData.AddressKeyFormat.PoliticalDivision1;
                  var apAddressCountry = LocationData.AddressKeyFormat.CountryCode;
                  var apPhoneNumber = LocationData.PhoneNumber;
                  var apSpecialInstructions = LocationData.SpecialInstructions;
                  var apAccessPointInfo = LocationData.AccessPointInformation;
                  var apHoursOfOperation = LocationData.StandardHoursOfOperation;

                  if (!apAddressState) {
                    apAddressState = "";
                  }

                  var description = '<div class="apAddress">' + 
                                    '<span class="addressLine1">'+ apAddressLine1 + '</span>' + ", " +
                                    '<span class="addressCity">' + apAddressCity + '</span>' + ", " +
                                    '<span class="addressState">' + apAddressState + '</span>' + " " + 
                                    '<span class="addressPostcode">' + apAddressPostcode + '</span>' + ", " +
                                    '<span class="addressCountry">' + apAddressCountry + '</span></div>';

                  if (apSpecialInstructions) {
                    var segment = apSpecialInstructions.Segment;
                    if (segment) {
                      description = description + '<div class="apInstructions"><span>' + segment + '</span></div>';
                    }
                  }

                  if (apAccessPointInfo) {
                    var imageURL = apAccessPointInfo.ImageURL;
                    if (imageURL) {
                      description = description + '<div class="apImage"><img src=' + imageURL + '></div>';
                    }
                  }

                  if (apPhoneNumber) {
                    description = description + '<div class="apPhoneNumber"><span class="title"><dr:resource key="PHONE_NUMBER"/></span><br/><span>' + apPhoneNumber + '</span></div>';
                  }
                  
                  if (apHoursOfOperation) {
                    var str = "";
                    var strArr = apHoursOfOperation.split(";");
                    for (n = 0; n < strArr.length; n++) {
                      if (n < strArr.length - 1) {
                        str = str + strArr[n] + "<br/>";
                      } else {
                        apHoursOfOperation = str + strArr[n];
                      }
                    }
                    description = description + '<div class="apOpHours"><span>' + apHoursOfOperation + '</span></div>';
                  }

                  pushpin.Title = apTitle;
                  pushpin.Description = description;
                  pinLayer.add(pushpin);
                  pushpin.setOptions({enableHoverStyle: pushpinHoverStyle});
                  Microsoft.Maps.Events.addHandler(pushpin, "click", displayInfobox);
                }

                function getMap() {
                  initMap();

                  var pinLayer = new Microsoft.Maps.Layer();
                  var infoboxOptions = {visible: false, title: "title", description: "description"};
                  pinInfobox = new Microsoft.Maps.Infobox(new Microsoft.Maps.Location(0, 0), infoboxOptions);
                  pinInfobox.setMap(null);
                  pinInfobox.setMap(map);

                  var $apSearchBtn = $("#dr_apSearchBtn");
                  var apCountryCode = $("#dr_apCountry").val();
                  var apPostalCode = $("#dr_apPostalCode").val();
                  var apSearchRadius = $("#dr_apSearchRadius").val();
                  var apMaxPoints = '<dr:resource key="SiteSetting_ACCESS_POINTS_MAX_NUMBER"/>';

                  if (apPostalCode != "") {
                    var $apSearchError = $("#dr_apSearchError");

                    $("#dr_apPostalCodeError").text("");

                    $.ajax({
                      type: "GET",
                      url: '<dr:action actionName="GetAccessPoints"/>',
                      data: {
                        zip: apPostalCode,
                        countryCode: apCountryCode,
                        range: apSearchRadius,
                        maxAccessPoints: apMaxPoints
                      },
                      dataType: "text",
                      success: function(data) {
                        var jsonStart = data.indexOf('{');

                        if (jsonStart < 0) {
                          $apSearchError.html('<dr:resource key="ACCESS_POINTS_SERVICE_UNCLASSIFIED_ERROR"/>');
                          $("#dr_apPostalCode").val("");
                          
                          if (bootstrapEnabled) {
                            $apSearchBtn.button("reset");
                          } else {
                            $apSearchBtn.prop("disabled", false);
                          }
                          return false;
                        }

                        var jsonData = data.substring(jsonStart);
                        var resObj = JSON.parse(jsonData.replace(/\n|\r/g, ""));
                        var locs = [];
                        var response = resObj.Response;
                        var statusCode = response.ResponseStatusCode;
                        
                        if (statusCode != 1) {
                          var errorMsg = response.Error.ErrorDescription;
                          $apSearchError.text(errorMsg);
                          $("#dr_apPostalCode").val("");

                          if (bootstrapEnabled) {
                            $apSearchBtn.button("reset");
                          } else {
                            $apSearchBtn.prop("disabled", false);
                          }
                          return false;
                        }

                        if ($apSearchError.text() != "") {
                          $apSearchError.text("");
                        }

                        var locations = resObj.SearchResults.DropLocation;

                        if (locations.constructor === Array) {
                          $.each(locations, function (index, LocationData) {
                            constructPushpin(pinLayer, locs, LocationData);
                          });
                        } else {
                          constructPushpin(pinLayer, locs, locations);
                        }

                        map.entities.push(pinLayer);

                        var bestview = Microsoft.Maps.LocationRect.fromLocations(locs);
                        map.setView({bounds: bestview});
                        
                        if (locs.length == 1) {
                          map.setView({zoom: 15});
                        }

                        if (bootstrapEnabled) {
                          if ($("#dr_apSearchPanelControl").css("display") != "none") {
                            $("#dr_apSearch .form-group").hide();
                            
                            if ($("#ZoomOutButton").length > 0) {
                              $("#ZoomOutButton, #ZoomInButton").hide();
                            }
                          }
                          $apSearchBtn.button("reset");
                        } else {
                          $apSearchBtn.prop("disabled", false);
                        }

                        $("#dr_apBody").css("opacity", "1");
                      },
                      error: function (xhr, ajaxOptions, thrownError) {
                        console.log(xhr.status);
                        console.log(thrownError);
                      }
                    });
                  } else {
                    $("#dr_apPostalCodeError").text('<dr:resource key="INVALID_INN_NUMBER_ERROR"/>');
                    $("#dr_apPostalCode").val("");

                    if (bootstrapEnabled) {
                      $apSearchBtn.button("reset");
                    } else {
                      $apSearchBtn.prop("disabled", false);
                    }
                  }
                }

                function displayInfobox(e) {
                  map.setView({center: e.target.getLocation()});

                  pinInfobox.setLocation(e.target.getLocation());
                  pinInfobox.setOptions({
                    title: e.target.Title,
                    description: e.target.Description,
                    visible: true
                  });

                  var $apInfo = $("#dr_apInfo");
                  var title = pinInfobox.getTitle();
                  var info = pinInfobox.getDescription();

                  $apInfo.empty();
                  $apInfo.append(info);
                  $apInfo.append('<div class="apTitle">' + title + '</div>');

                  $("#dr_apMakeBtn").prop("disabled", false);
                }

                function hideInfobox(e) {
                  if (pinInfobox != null) {
                    pinInfobox.setOptions({visible: false});
                  }
                }

                function fillInShippingAddress() {
                  var companyName = $("#dr_apInfo .apTitle").text();
                  var address = $("#dr_apInfo .apAddress").text();

                  if (address != "") {
                    var addressArr = address.split(",");
                    var addressLine1 = $("#dr_apInfo .apAddress .addressLine1").text().trim();
                    var city = $("#dr_apInfo .apAddress .addressCity").text().trim();
                    var state = $("#dr_apInfo .apAddress .addressState").text().trim();
                    var postcode = $("#dr_apInfo .apAddress .addressPostcode").text().trim();
                    var country = $("#dr_apInfo .apAddress .addressCountry").text().trim();

                    var billingFirstName = $("#billingName1").val().trim();
                    var billingLastName = $("#billingName2").val().trim();
                    var billingPhoneNumber = $("#billingPhoneNumber").val().trim();
                    var billingEmail = "";
                    <logic:if name="isAuthenticated" value="true" op="equal">
                      <logic:then>
                        billingEmail = '<bean:write name="page" property="userSession.user.loginID"/>';
                      </logic:then>
                      <logic:else>
                        billingEmail = $("#email").val().trim();
                      </logic:else>
                    </logic:if>

                    var $shippingFirstName = $("#shippingName1");
                    var $shippingLastName = $("#shippingName2");
                    var $shippingPhoneNumber = $("#shippingPhoneNumber");
                    var $shippingEmail = $("#shippingEmail");
                    var $shippingCompanyName = $("#shippingCompanyName");

                    $("#shippingAddress1").val(addressLine1);
                    $("#shippingCity").val(city);
                    $("#shippingPostalCode").val(postcode);
                    $("#shippingCountry").val(country);

                    if (state != "") {
                      $("#shippingState").val(state);
                    } else {
                      $("#shippingState option").removeAttr("selected");
                      $("#shippingState option:eq(1)").prop("selected", "selected");
                    }

                    if ($shippingFirstName.val() == "") {
                      $shippingFirstName.val(billingFirstName);
                    }
                    if ($shippingLastName.val() == "") {
                      $shippingLastName.val(billingLastName);
                    }
                    if ($shippingPhoneNumber.val() == "") {
                      $shippingPhoneNumber.val(billingPhoneNumber);
                    }
                    if ($shippingEmail.val() == "") {
                      $shippingEmail.val(billingEmail);
                    }
                    $shippingCompanyName.val(companyName);

                    $("#dr_shippingContainer").show();
                  }

                  if (!bootstrapEnabled) {
                    $("#dr_apOverlay").popup("hide");
                  }
                }
                
                function sortCountryDropdown(apCountryOptions) {                  
                  var apCountryArr = apCountryOptions.map(function(i, o) {
                    return {
                      t: $(o).text(),
                      v: o.value
                    };
                  }).get();
                  
                  apCountryArr.sort(function(o1, o2) {
                    return o1.t > o2.t ? 1 : o1.t < o2.t ? -1 : 0;
                  });
                  apCountryOptions.each(function(i, o) {
                    o.value = apCountryArr[i].v;
                    $(o).text(apCountryArr[i].t);
                  });
                }
                
                function createCountryDropdown(apCountrySelect) {                  
                  var apSupportedCountries = '<bean:write name="apSupportedCountries" filter="false" ignore="true"/>';
                  var supportedCountriesArr = apSupportedCountries.split(",");

                  for (var i = 0; i < supportedCountriesArr.length; i++) {
                    var countryCode = supportedCountriesArr[i].trim();
                    // Get localized country names from #shippingCountry
                    var countryName = $("#shippingCountry option[value=" + countryCode + "]").text();
                    if (countryName != "") {
                      apCountrySelect.options.add(new Option(countryName, countryCode));
                    }
                  }

                  // Sort Access Points country select options
                  var apCountryOptions = $("#dr_apCountry option");
                  sortCountryDropdown(apCountryOptions);
                }
                
                function createRadiusDropdown(apSearchRadiusSelect) {
                  var apSearchRadiusOptions = '<bean:write name="searchRadiusOptions" filter="false" ignore="true"/>';
                  var searchRadiusOptionsArr = apSearchRadiusOptions.split(",");                  

                  for (var i = 0; i < searchRadiusOptionsArr.length; i++) {
                    var radius = searchRadiusOptionsArr[i].trim();
                    apSearchRadiusSelect.options.add(new Option(radius + " <dr:resource key="SEARCH_RADIUS_UNIT"/>", radius));
                  }
                }

                function setDefaultCountry($apCountry, defaultCountry) {                  
                  $apCountry.val(defaultCountry);
                  if ($apCountry.val() == null) {
                    $apCountry.val("US");
                  }
                }

                function getPopupBox() {
                  var apPopupPath = '<dr:action actionName="DisplayAccessPointsOverlayPage"/>';
                  bootstrapEnabled = (typeof $().modal == "function");
                  
                  if (bootstrapEnabled) {
                    apPopupPath = '<dr:action actionName="DisplayAccessPointsModalPage"/>';
                  } else {
                    var popupOverlayLen = $('script[src="/DRHM/Storefront/Library/scripts/jquery/plugins/jquery.popup-overlay.js"]').length;
                    var js = document.createElement("script");
                    js.type = "text/javascript";

                    if (popupOverlayLen < 1) {
                      if (window.jQuery) {
                        var arr = $.fn.jquery.split('.');
                        if (arr[0] > 1 || (arr[0] == 1 && arr[1] >= 8)) {
                          //jQuery is loaded, then do nothing
                        } else {
                          document.writeln('<scr'+'ipt type="text/javascript" src="<dr:resource key="JQUERY_UPDATE_FILEPATH"/>"></scr'+'ipt>');
                        }
                      } else {
                        document.writeln('<scr'+'ipt type="text/javascript" src="<dr:resource key="JQUERY_UPDATE_FILEPATH"/>"></scr'+'ipt>');
                      }
                      js.src = '<dr:resource key="SiteSetting_JQUERY_POPUP_OVERLAY_PATH"/>';
                      document.body.appendChild(js);
                    }
                  }              

                  $.ajax({
                    method: "GET",
                    url: apPopupPath,
                    dataType: "html"
                  }).done(function(data) {
                    // Append overlay HTML
                    $("body").prepend(data);
                    
                    // Create Access Points country select according to supported countries
                    var apCountrySelect = document.getElementById("dr_apCountry");
                    createCountryDropdown(apCountrySelect);

                    // Create Access Points search radius select
                    var apSearchRadiusSelect = document.getElementById("dr_apSearchRadius");
                    createRadiusDropdown(apSearchRadiusSelect);
                    
                    // Set the default for Access Points country select
                    var $apCountry = $("#dr_apCountry");
                    var defaultCountry = $("#billingCountry").val();
                    setDefaultCountry($apCountry, defaultCountry);

                    // Find Access Points
                    $("#dr_apSearchBtn").on("click", function() {
                      if (bootstrapEnabled) {
                        $(this).button("loading");
                      } else {
                        $(this).prop("disabled", true);
                      }

                      $("#dr_apBody").css("opacity", "0.5");
                      $("#dr_apInfo").empty();
                      $("#dr_apMakeBtn").prop("disabled", true);
                      getMap();
                    });
                    
                    $("#dr_apPostalCode").keydown(function(event) {
                      if (event.keyCode == 13) {
                        $("#dr_apPostalCode").blur();
                        $("#dr_apSearchBtn").trigger("click");
                      }
                    });

                    // Populate the selected shipping address in the shipping fields
                    $("#dr_apMakeBtn").on("click", function() {
                      fillInShippingAddress();
                      
                      $("#dr_shipping span.dr_error").each(function() {
                        if ($(this).html() != "") {
                          $(this).html("");
                        }
                      });
                    });

                    if (bootstrapEnabled) {
                      $("#dr_apModal").on("shown.bs.modal", function() {
                        $("#dr_apPostalCode").focus();
                      });

                      $("#dr_apModal").on("hidden.bs.modal", function() {
                        if ($("#dr_apSearchError").text() != "") {
                          $("#dr_shippingContainer").after('<div id="dr_apServiceError" class="alert alert-danger">' + '<dr:resource key="ACCESS_POINTS_SERVICE_ERROR"/>' + '</div>');
                        }

                        hideInfobox();
                      });

                      $("#dr_apSearchPanelControl a").on("click", function() {
                        $("#dr_apSearch .form-group").toggle("fast");
                      });

                      $(window).resize(function() {
                        if ($(window).width() >= 768) {
                          if ($("#dr_apSearch .form-group").css("display") == "none") {
                            $("#dr_apSearch .form-group").show();
                          }

                          if ($("#ZoomOutButton").length > 0) {
                            if ($("#ZoomOutButton").css("display") == "none") {
                              $("#ZoomOutButton, #ZoomInButton").show();
                            }
                          }
                        }
                      });
                    } else {
                      $("#dr_apOverlay").popup({
                        transition: "all 0.3s",
                        onclose: function() {
                          if ($("#dr_apSearchError").text() != "") {
                            $("#dr_locateAccessPoints").after('<div id="dr_apServiceError" class="dr_error">' + '<dr:resource key="ACCESS_POINTS_SERVICE_ERROR"/>' + '</div>');
                          }

                          hideInfobox();
                        },
                        opentransitionend: function() {
                          $("#dr_apPostalCode").focus();
                        }
                      });
                    }

                    // Show Access Points popup
                    $("#dr_apLocateBtn").on("click", function() {
                      initPopup();

                      if (bootstrapEnabled) {
                        $("#dr_apSearch .form-group").show();
                        $("#dr_apSearchPanelControl").hide();
                        $("#dr_apModal").modal("show");
                      } else {
                        $("#dr_apOverlay").popup("show");
                      }

                      if ($("#dr_apServiceError").length > 0) {
                        $("#dr_apServiceError").remove();
                      }
                    });

                    // Auto-trigger popup if shipping address fields are empty, and shoppers process to the next page
                    if (($("fieldset#dr_shipping label[for=shippingAddress1] .dr_error").text().trim() != "") && ($("#shippingAddress1").val() == "")) {
                      $("#dr_apLocateBtn").trigger("click");
                    }

                    initMap();
                  });
                }

                return {
                  $shippingFields: $shippingFields,
                  $shippingSelect: $shippingSelect,
                  getPopupBox: getPopupBox
                }
              }();

              function initDRAP() {
                drAP.getPopupBox();
              }

              $(function() {
                // "Shipping address is different than billing" checkbox will be checked and hidden
                $("input#shippingDifferentThanBilling, #shippingDifferentThanBillingIndicator label").hide();
                $("#shippingDifferentThanBilling").prop("checked", true);
                $("#dr_orderIsAGiftCheckbox").hide();

                // Disable shipping address fields
                drAP.$shippingFields.prop("readonly", true);
                drAP.$shippingSelect.prop("disabled", true);
                drAP.$shippingFields.css({"background-color": "#E6E6E6", "color": "#808080"});
                drAP.$shippingSelect.css("background-color", "#E6E6E6");

                // Hide PayPal payment
                if ($('fieldset#dr_payment > [id^="dr_PayPal"]').length > 0) {
                  $('fieldset#dr_payment > [id^="dr_PayPal"]').hide();
                }

                // Clean the shipping fields
                if (typeof(Storage) !== "undefined") {
                  if (localStorage.shippingFields == "false") {
                    $("#shippingAddress1").val("");
                    $("#shippingCity").val("");
                    $("#shippingPostalCode").val("");
                    $("#shippingCompanyName").val("");
                  }
                }

                if ($("#shippingAddress1").val() != "") {
                  $("#dr_shippingContainer").show();
                } else {
                  $("#dr_shippingContainer").hide();
                }

                // Enable the select before submitting the form
                $("#checkoutButton").on("click", function() {
                  drAP.$shippingSelect.prop("disabled", false);
                });

              });
            </script>
          </logic:equal>
          <logic:notEqual name="req" property="accessPointShippingMethod" value="true">
            <script>
              $(function() {
                // Clean the shipping fields
                if (typeof(Storage) !== "undefined") {
                  if (localStorage.shippingFields == "false") {
                    $("#shippingAddress1").val("");
                    $("#shippingCity").val("");
                    $("#shippingPostalCode").val("");
                    $("#shippingCompanyName").val("");
                  }
                }
              });
            </script>
          </logic:notEqual>
        </logic:equal>
      </logic:present>
    </logic:then>
  </logic:if>
</dr:page>