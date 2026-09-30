// ============================================================================
//  ArkZ3DHedron.dcl - Dialog Control Language Interface
// ============================================================================

// ----------------------------------------------------------------
//	hedron.dcl
//
hedron : dialog {
  label = "Ark-Z 3D Polyhedron & Geodesic Studio";
//
: row {
	alignment = centered;
	fixed_width = true;
	fixed_height = true;  
	: image {
		key = "#img_logo" ;
		alignment = centered;
		fixed_width = true;
		fixed_height = true;    
		is_tab_stop = false ;
		width = 14;
		aspect_ratio = 0.45;
		color = dialog_background;
	}
	: column {
		: paragraph {
			key = "#arkz";
			: text_part {
				label = " ";
				alignment = centered;
			}
			: text_part {
				label = "ARK-Z ARQUITETURA LTDA";
				alignment = centered;
			}
			: text_part {
				label = "Applications for AutoCAD";
				alignment = centered;
			}
		}
	}	
}
//
: image {key = "sep1"; color = dialog_background; width = 1; height = 0.5;}
//
  : row {
//
    : boxed_column {
      label = "Geometry Setup";
	  alignment = centered;
	  fixed_width = true;
      : row {
        : button { key = "picksize"; label = "Size <"; }
        : edit_box { fixed_width = true; label = ""; key = "hdsize"; edit_width = 5; }
        : text_part { key = "unit_lbl"; width = 2; }
      }
      : radio_row {
        : radio_button { key = "edge"; label = "Edge "; value = "1"; }
        : radio_button { key = "radius"; label = "Radius"; }
      }

      : button { key = "pickpoint"; label = "Center point <"; }
	  : row {
         : edit_box { fixed_width = true; label = "X"; key = "X"; edit_width = 6; }
         : edit_box { fixed_width = true; label = "Y"; key = "Y"; edit_width = 6; }
         : edit_box { fixed_width = true; label = "Z"; key = "Z"; edit_width = 6; }
	  }

      : boxed_column {
        label = "Output Engine";
	    alignment = centered;
	    fixed_height = true;  
        : radio_button { key = "mesh"; value = "1"; label = "Polyface Mesh (Legacy)"; }
        : radio_button { key = "subdmesh"; label = "Sub-D Mesh (Modern)"; }
        : radio_button { key = "solid"; label = "3D Solid (CSG)"; }
        : radio_button { key = "wireframe"; label = "3D Wireframe (Edges)"; }
        : toggle { key = "autolayer"; label = "Auto-Layer by Polygon Sides"; value = "0"; }
      }
    }
//
    : column {
	   fixed_height = true;
	   alignment=centered;
	  : boxed_column {
	    label = "Presets :";
        : popup_list {
          key = "preset";
          edit_width = 22;
          list = "Custom\nTetrahedron\nCube\nOctahedron\nDodecahedron\nIcosahedron\n \nCubeoctahedron\nRhombicuboctahedron\nRhombicosidodecahedron\nFootball (Truncated Icos.)\n \nRhombic Dodecahedron (Catalan)\nRhombic Triacontahedron (Catalan)\nTetrakis Hexahedron (Catalan)\n \nGeodesic Dome 1V\nGeodesic Dome 2V\nGeodesic Dome 3V";
        }
        : spacer { height = 1; }
	  }
        : spacer { height = 1; }
      : boxed_column {
        label = "Polygons Around Vertex";
        key = "Polygons";
        : edit_box { label = "1st polygon: "; key = "0"; edit_width = 7; }
		  fixed_heigh = true;
        : popup_list { edit_width = 6; key = "1"; list = "None\n3\n4\n5\n6\n7\n8\n10"; label = "2nd polygon: "; }
        : popup_list { edit_width = 6; key = "2"; list = "None\n3\n4\n5\n6\n7\n8"; label = "3rd polygon: "; }
        : popup_list { edit_width = 6; key = "3"; value = 6; list = "None\n3\n4\n5\n6\n7\n8"; label = "4th polygon: "; }
        : popup_list { edit_width = 6; key = "4"; value = 6; list = "None\n3\n4\n5\n6\n7\n8"; label = "5th polygon: "; }
        : spacer { height = 1; }
	  }
    }
//
    : boxed_column {
	  alignment = centered;
	  fixed_height = true;  
      label = "Interactive Preview";
      : row {
        : text_part { width = 3; key = "flist"; }
        : text_part { width = 3; key = "plist"; }
      }
	  : spacer { height = 0.25; }
      : image_button {
	    label = "Preview";
	    color = 0;
	    width = 30;
	    height = 13.5;
	    fixed_width = true;
	    fixed_heigh = true;
	    key = "previewimage";
	  }
      : column {
         fixed_height = true;
         alignment=centered;
         : row {
            : button { key = "v_top"; label = "Top"; }
            : button { key = "v_front"; label = "Front"; }
      	}
         : row {
            : button { key = "v_se"; label = "SE Iso"; }
            : button { key = "v_sw"; label = "SW Iso"; }
        }
      }
    }
//
  }
//
  : image {key = "sep2"; color = dialog_background; width = 1; height = 0.5;}
//
  : row {
    fixed_width = true;
	alignment=centered;
    : button { key = "OK"; label = "OK"; fixed_width = true; is_default = true; mnemonic = "O"; }
    : button { key = "Cancel"; label = "Cancel"; fixed_width = true; is_cancel = true; mnemonic = "C"; }
	: button { key = "help"; width = 12; label = " Help "; fixed_width = true; is_default = false; mnemonic = "H";}
    : button { key = "advanced"; label = "Advanced >"; }
  }
}  // end dialog

// ----------------------------------------------------------------
//	hedronadvanced.dcl
//

hedronadvanced : dialog {
  label = "Ark-Z 3D Polyhedron & Geodesic Studio";
: row {
	alignment = centered;
	fixed_width = true;
	fixed_height = true;  
	: image {
		key = "#img_logo" ;
		alignment = centered;
		fixed_width = true;
		fixed_height = true;    
		is_tab_stop = false ;
		width = 14;
		aspect_ratio = 0.45;
		color = dialog_background;
	}
	: column {
		: paragraph {
			key = "#arkz";
			: text_part {
				label = " ";
				alignment = centered;
			}
			: text_part {
				label = "ARK-Z ARQUITETURA LTDA";
				alignment = centered;
			}
			: text_part {
				label = "Applications for AutoCAD";
				alignment = centered;
			}
		}
	}	
}
//
: image {key = "sep1"; color = dialog_background; width = 1; height = 0.5;}
//
: row {
//
: column {
//
  : row {
//
    : boxed_column {
      label = "Geometry Setup";
	  alignment = centered;
	  fixed_width = true; 
      : row {
        : button { key = "picksize"; label = "Size <"; }
        : edit_box { fixed_width = true; label = ""; key = "hdsize"; edit_width = 5; }
        : text_part { key = "unit_lbl"; width = 2; }
      }
      : radio_row {
        : radio_button { key = "edge"; label = "Edge "; }
        : radio_button { key = "radius"; value = "1"; label = "Radius"; }
      }

      : button { key = "pickpoint"; label = "Center point <"; }
	  : row {
         : edit_box { fixed_width = true; label = "X"; key = "X"; edit_width = 6; }
         : edit_box { fixed_width = true; label = "Y"; key = "Y"; edit_width = 6; }
         : edit_box { fixed_width = true; label = "Z"; key = "Z"; edit_width = 6; }
	  }

      : boxed_column {
        label = "Output Engine";
	    alignment = centered;
	    fixed_height = true;  
        : radio_button { key = "mesh"; value = "1"; label = "Polyface Mesh (Legacy)"; }
        : radio_button { key = "subdmesh"; label = "Sub-D Mesh (Modern)"; }
        : radio_button { key = "solid"; label = "3D Solid (CSG)"; }
        : radio_button { key = "wireframe"; label = "3D Wireframe (Edges)"; }
        : toggle { key = "autolayer"; label = "Auto-Layer by Polygon Sides"; value = "0"; }
      }
//
    }
//
    : column {
	   fixed_height = true;
	   alignment=centered;
	  : boxed_column {
	    label = "Presets :";
        : popup_list {
          key = "preset";
          edit_width = 22;
          list = "Custom\nTetrahedron\nCube\nOctahedron\nDodecahedron\nIcosahedron\n \nCubeoctahedron\nRhombicuboctahedron\nRhombicosidodecahedron\nFootball (Truncated Icos.)\n \nRhombic Dodecahedron (Catalan)\nRhombic Triacontahedron (Catalan)\nTetrakis Hexahedron (Catalan)\n \nGeodesic Dome 1V\nGeodesic Dome 2V\nGeodesic Dome 3V";
        }
        : spacer { height = 1; }
	  }
        : spacer { height = 1; }
      : boxed_column {
        label = "Polygons Around Vertex";
        key = "Polygons";
        : edit_box { label = "1st polygon: "; key = "0"; edit_width = 7; }
		  fixed_heigh = true;
        : popup_list { edit_width = 6; key = "1"; list = "None\n3\n4\n5\n6\n7\n8\n10"; label = "2nd polygon: "; }
        : popup_list { edit_width = 6; key = "2"; list = "None\n3\n4\n5\n6\n7\n8"; label = "3rd polygon: "; }
        : popup_list { edit_width = 6; key = "3"; value = 6; list = "None\n3\n4\n5\n6\n7\n8"; label = "4th polygon: "; }
        : popup_list { edit_width = 6; key = "4"; value = 6; list = "None\n3\n4\n5\n6\n7\n8"; label = "5th polygon: "; }
        : spacer { height = 1; }
	  }
    }
//
}
//
    : boxed_column {
      label = "Colors";
      : row {
	    alignment = centered;
	    fixed_height = true;
		fixed_width = true;
	    : column {
          : text { width = 10; key = "t0"; fixed_width = true;}
          : text { width = 10; key = "t1"; }fixed_width = true;
		}
		: column {
		  : row {
            : image_button { key = "i0"; color = 0; width = 8; height = 1.3; fixed_width = true; fixed_height = true;}
            : edit_box { fixed_width = true; key = "c0"; edit_width = 6; }
		  }
		  : row {
		    : image_button { key = "i1"; color = -15; width = 8; height = 1.3; fixed_width = true; fixed_height = true;}
            : edit_box { fixed_width = true; key = "c1"; edit_width = 6; }
		  }
		}
  	  : spacer { width = 1; fixed_width = true;}
	    : column {
          : text { width = 10; key = "t2"; fixed_width = true;}
          : text { width = 10; key = "t3"; }fixed_width = true;
		}
		: column {
		  : row {
            : image_button { key = "i02"; color = 0; width = 8; height = 1.3; fixed_width = true; fixed_height = true;}
            : edit_box { fixed_width = true; key = "c2"; edit_width = 6; }
		  }
		  : row {
		    : image_button { key = "i3"; color = -15; width = 8; height = 1.3; fixed_width = true; fixed_height = true;}
            : edit_box { fixed_width = true; key = "c3"; edit_width = 6; }
		  }
		}
	  }
    }
//
}
//
    : column {
    : boxed_column {
	  alignment = centered;
	  fixed_height = true;  
      label = "Interactive Preview";
      : row {
        : text_part { width = 3; key = "flist"; }
        : text_part { width = 3; key = "plist"; }
      }
	  : spacer { height = 0.25; }
      : image_button {
	    label = "Preview";
	    color = 0;
	    width = 30;
	    height = 13.5;
	    fixed_width = true;
	    fixed_heigh = true;
	    key = "previewimage";
	  }
      : column {
         fixed_height = true;
         alignment=centered;
         : row {
            : button { key = "v_top"; label = "Top"; }
            : button { key = "v_front"; label = "Front"; }
      	}
         : row {
            : button { key = "v_se"; label = "SE Iso"; }
            : button { key = "v_sw"; label = "SW Iso"; }
        }
      }
    }
//
    : spacer { height = 1; }
//
    : boxed_column {
	  fixed_heigh = true;
      label = "Special Operations";
      : popup_list { label = "Triangulation: "; key = "triang"; edit_width = 6; list = "None\n1\n2\n3"; }
      : edit_box { fixed_width = true; label = "Truncation:"; key = "trunc";}
      : slider { value = "0"; width = 25; min_value = "0"; max_value = "50"; key = "truncation"; }
    }
//
  }
}
//
  : image {key = "sep2"; color = dialog_background; width = 1; height = 0.5;}
//
  : row {
    fixed_width = true;
	alignment=centered;
    : button { key = "OK"; label = "OK"; fixed_width = true; is_default = true; mnemonic = "O"; }
    : button { key = "Cancel"; label = "Cancel"; fixed_width = true; is_cancel = true; mnemonic = "C"; }
    : button { key = "help"; width = 12; label = " Help "; fixed_width = true; is_default = false; mnemonic = "H";}
    : button { key = "simple"; label = "< Simple"; fixed_width = true; mnemonic = "S"; }
  }
} // end dialog

// ----------------------------------------------------------------
//	ArkZ3DHedron_Help.dcl
//
ArkZ3DHedron_Help : dialog {
	label = "Ark-Z Arquitetura Information" ;
	: image {
		key = "#img_logo" ;
		alignment=centered;
		is_tab_stop = false ;
		width = 14;
		aspect_ratio = 0.45;
		fixed_width = true;
		color = dialog_background;
	}
	: list_box {
		width = 65 ;
		height = 16 ;
		key = "lstAbout" ;
		fixed_width = false;
		fixed_width_font = true;
	}
	: text {
		label = "Program information:";
	}
	: text {
		key = "reg_dat";
		fixed_width_font = true;
		height = 4.5 ;
	}
	: button {
		fixed_width = true ;
		is_cancel = true ;
		is_default = true ;
		key = "btnOK" ;
		label = "OK" ;
		alignment=centered;		 
		width = 12 ;
	}
} // end dialog
