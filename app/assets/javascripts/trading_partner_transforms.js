$(document).ready(function() {
  var form = $("#trading_partner_transforms_form");
  if (form.length == 0) {
    return;
  }

  var actionSelect = $("#trading_partner_transform_request_end_date_action");
  var changeModeRadios = $("input[name='trading_partner_transform_request[change_mode]']");
  var reasonCodeSelect = $("#trading_partner_transform_request_reason_code");
  var fileInput = $("#source_xml_files");

  function syncPrepFields() {
    var action = actionSelect.val();
    var showEndDate = (action == "change") && (changeModeRadios.filter(":checked").val() == "terminate");

    // Show only the description for the selected action
    $(".prep-action-desc").hide();
    $("#prep-desc-" + action).show();

    // Policy state and benefit status only apply to Remove End Date
    $("#remove-fields").toggle(action == "remove");
    $("#remove-fields select").prop("disabled", action != "remove");

    // Terminate or cancel sub-options only apply to that action
    $("#change-mode-fields").toggle(action == "change");
    changeModeRadios.prop("disabled", action != "change");

    // The end date only applies to terminate
    $("#terminate-end-date").toggle(showEndDate);
    $("#terminate-end-date input").prop("disabled", !showEndDate);

    $("#apply-btn").prop("disabled", action == "none");
  }

  function syncGenerateSection() {
    var hasCode = reasonCodeSelect.val() != "";
    $("#generate-btn, #generate-source-btn").prop("disabled", !hasCode);
  }

  function syncUploadSection() {
    $("#transform-upload-btn").prop("disabled", fileInput[0].files.length == 0);
  }

  function resetFormState() {
    form[0].reset();
    syncPrepFields();
    syncGenerateSection();
    syncUploadSection();
  }

  actionSelect.on("change", syncPrepFields);
  changeModeRadios.on("change", syncPrepFields);
  reasonCodeSelect.on("change", syncGenerateSection);
  fileInput.on("change", syncUploadSection);

  // Downloads do not reload the page, so reset the form after the download starts
  $("#generate-btn, #generate-source-btn, #transform-upload-btn").on("click", function() {
    setTimeout(resetFormState, 2000);
  });

  // Clear the form when the browser restores the page from its back/forward cache
  window.addEventListener("pageshow", function(event) {
    if (event.persisted) {
      resetFormState();
    }
  });

  syncPrepFields();
  syncGenerateSection();
  syncUploadSection();
});
