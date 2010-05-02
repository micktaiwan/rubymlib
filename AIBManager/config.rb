CONFIG = {
  
  :paths => {
    :ref =>'//fr0-filer24/SW_REPOSITORY/SWN/FODM/REF/',
    :sys => 'C:/StarTeam/NSS_FOD_MIDDLEWARE/system-docs/'
  },
  
  :docs => {
    :sys => {
      :single => [
      {:name=>'FOD M. System Plan',:conv=> /FODM_SP_.+\.doc/, :dir=>'Plans'},
      {:name=>'FOD M. V&V Plan',:conv=>/FODM_VVP_.+\.doc/, :dir=>'Plans'},
      {:name=>'FOD M. Configuration Management Plan',:conv=>'FODM_CMP_ref_#.doc', :dir=>'Plans'},
      {:name=>'FOD M. Requirements Dossier',:conv=>'FODM_RD_ref_#.doc', :dir=>'Definition'},
      {:name=>'FOD M. Architecture Dossier',:conv=>'FODM_ARD_ref_#.doc', :dir=>'Definition'},
      {:name=>'FOD M. Validation Dossier',:conv=>'FODM_VD_ref_#.doc', :dir=>'Validation'},
      {:name=>'FOD M. actions follow-up table',:conv=>'FODM_Actions_<yymmdd> .<ext>', :dir=>'Progress'}
      ],
      
      :groups => [
      {:name=>'FOD M. System Interface Documents',:conv=>'FODM_SID<xxx>_ref_#.doc', :dir=>'Operational'},
      {:name=>'FOD M. Operations & Maintenance data for A/C manuals',:conv=>'FODM_<xxx>_ref_#.doc', :dir=>'Operational'},
      #{:name=>'Reading sheets for documents owned by the FOD M. System Leader',:conv=>'docname_RSheet.doc  (besides the document)
      {:name=>'Reading sheets for external documents',:conv=>'docname_RSheet.doc', :dir=>'Readings'},
      {:name=>'FOD M. progress meeting reports',:conv=>'FODM_Progress_<yymmdd> _ref.doc', :dir=>'Progress'},
      {:name=>'FOD M. Compliance Matrix regarding input documents',:conv=>'FODM_CM<xxx>_ref_#.doc', :dir=>'Definition'},
      {:name=>'FOD M. Mock-up material',:conv=>'<xxx>', :dir=>'Definition/Mockup'}
      ]
    }
  }
}
