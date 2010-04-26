<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>webRainbow</title>
<script language="javascript" type="text/javascript">
var raibow_i2c_id;
var color = "#FFFFFF" , rainbowColor = 99;
matrix = new Array();

function connect(ID,X,Y,r,g,b)
{

if (window.XMLHttpRequest)
  {
  xmlhttp=new XMLHttpRequest();
  }
else
  {
  xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
  }
xmlhttp.onreadystatechange=function()
  {
  }
xmlhttp.open("GET","connect.php?ID="+ID+"&X="+X+"&Y="+Y+"&r="+r+"&g="+g+"&b="+b,true);
xmlhttp.send();
}


function pick_color(col) {
	switch (col) {
		case 0:
		color = "#FF0000";
		rainbowColor = 0;
		break;
		case 1:
		color = "#00FF00";
		rainbowColor = 1;
		break;
		case 2:
		color = "#0000FF";
		rainbowColor = 2;
		break;
		case 100:
		color = "#000000";
		rainbowColor = 100;
		break;
		default:
		color = "#FFFFFF";
		rainbowColor = 99;
		break;
	}  
}
function clickId(x,y) {
	document.getElementById(x+"-"+y).style.background = color;
	matrix[0] = x;
	matrix[1] = y;
	switch (rainbowColor) {
		case 0:
		matrix[2] = "15";
		matrix[3] = "00";
		matrix[4] = "00";
		break;
		case 1:
		matrix[2] = "00";
		matrix[3] = "15";
		matrix[4] = "00";
		break;
		case 2:
		matrix[2] = "00";
		matrix[3] = "00";
		matrix[4] = "15";
		break;
		case 99:
		matrix[2] = "15";
		matrix[3] = "15";
		matrix[4] = "15";
		break;
		case 100:
		matrix[2] = "00";
		matrix[3] = "00";
		matrix[4] = "00";
		break;
	}	
	
	generate_command();
}

function generate_command() {
	i2c = document.getElementById('i2c_bus').value;
	document.getElementById('result').innerHTML += "<br />SetPixelXY("+i2c+", "+matrix[0]+", "+matrix[1]+", "+matrix[2]+", "+matrix[3]+", "+matrix[4]+");  ";
	connect(i2c,matrix[0],matrix[1],matrix[2],matrix[3],matrix[4])
	
}

function clean_all() {
	var x,y;
	for (x=0; x<8; x++) {
		for (y=0; y<8; y++) {
			document.getElementById(x+"-"+y).style.background = "#000000";
			}
	}
	document.getElementById('result').innerHTML = "";
	
	
}
function change_matrix_number() {
	id = document.getElementById('matrix_number').value;
	switch(id) {
	case "2":
	document.getElementById('rainbow_1').style.display = "block";
	document.getElementById('rainbow_2').style.display = "block";
	document.getElementById('rainbow_3').style.display = "none";
	break;
	case "3":
	document.getElementById('rainbow_1').style.display = "block";
	document.getElementById('rainbow_2').style.display = "block";
	document.getElementById('rainbow_3').style.display = "block";
	break;
	break;
	default:
	document.getElementById('rainbow_1').style.display = "block";
	document.getElementById('rainbow_2').style.display = "none";
	document.getElementById('rainbow_3').style.display = "none";
	break;
	}
}
</script>

</head>

<body>
<h1>webRainbow!</h1>

<select id="matrix_number" name="matrix_number" onchange="change_matrix_number()">
  <option value="1" selected="selected">1</option>
  <option value="2">2</option>
  <option value="3">3</option>
</select>

<div id="container">
<div id="rainbow_1" style=" width: 300px; float: left">
<h2>Matrix 1</h2>
<table width="240" border="0" id="color_table" bgcolor="#ffffff" bordercolor="#CCCCCC"; cellpadding="1">
  <?php
  for ($j=7; $j>=0; $j--) {
  echo "
  <tr>";
  for($i = 0; $i < 8; $i++) {
  echo "
  <td bgcolor=\"#000000\" onmouseover=\"over(".$i.",".$j.")\"  onmouseout=\"out(".$i.",".$j.")\" onclick=\"clickId(".$i.",".$j.")\" id=\"".$i."-".$j."\"><img src=\"img/dot.png\" /></td>";
  	}
  echo "
  </tr>
 
  ";
  }
  ?> 

</table>

<h3>Pick a color</h3>
<table width="240" border="1">
  <tr>
    <td width="48px" bgcolor="#FF0000" onclick="pick_color(0)">&nbsp;</td>
    <td width="48px" bgcolor="#00FF00" onclick="pick_color(1)">&nbsp;</td>
    <td width="48px" bgcolor="#0000FF" onclick="pick_color(2)">&nbsp;</td>
    <td width="48px" bgcolor="#FFFFFF" onclick="pick_color(99)">&nbsp;</td>
    <td width="48px" bgcolor="#000000" onclick="pick_color(100)" style="color:#FFFFFF"><div align="center">OFF</div></td>
  </tr>
</table><br />
<p>Select the i2c bus ID: <input name="i2c_bus" id="i2c_bus" type="text" value="3" size="2" maxlength="2" />
</p>

<input name="clean" type="button" value="clean" onclick="clean_all()" /><br />
</div>

</div>
<div style="clear:both"></div>
<div id="showthecode"><a href="javascript:void(0);" onclick="document.getElementById('result').style.display = 'block'">Show the code....</a><br /></div>
<div id="result" style="display:none"></div>
</body>
</html>
