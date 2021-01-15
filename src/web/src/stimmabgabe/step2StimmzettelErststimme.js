import { Button, makeStyles, FormControl, FormLabel, RadioGroup, Radio, FormControlLabel } from "@material-ui/core";


const useStyles = makeStyles(theme => ({
  button: {
    marginRight: theme.spacing(1),
  },
  instructions: {
    marginTop: theme.spacing(1),
    marginBottom: theme.spacing(1),
  },
}));


export default function Step2StimmzettelErststimme(props) {
  const classes = useStyles()

  const handleNext = () => {
    props.setActiveStep((prevActiveStep) => prevActiveStep + 1);
  };
  const handleBack = () => {
    props.setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const handleChange = (event) => {
    props.setErststimme(+event.target.value);
  };


  return <>
    <div>
      Sie haben 1 (eine) Stimme.
    </div>
    <div>
      <FormControl component="fieldset">
        <FormLabel component="legend">Erststimme für die Wahl einer oder eines Stimmkreisabgeordneten</FormLabel>
        <RadioGroup value={props.erststimme} onChange={handleChange}>
          {props.stimmzettelErststimme.map((kandidat, index) => (
            <FormControlLabel key={kandidat.nummer} value={kandidat.nummer} control={<Radio />} label={`${index + 1}. ${kandidat.name} (${kandidat.partei})`}></FormControlLabel>
          ))}
        </RadioGroup>
      </FormControl>
      <Button variant="contained" onClick={() => props.setErststimme(null)}>Zurücksetzen</Button>
    </div>
    <div>
      <Button disabled={props.activeStep === 0} onClick={handleBack} className={classes.button}>
        Zurück
              </Button>
      <Button
        variant="contained"
        color="primary"
        onClick={handleNext}
        className={classes.button}
      >
        Weiter
      </Button>
    </div>
  </>
}