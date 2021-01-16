import { Button, makeStyles } from "@material-ui/core";
import { Alert, AlertTitle } from '@material-ui/lab';
import { useState } from "react";

const useStyles = makeStyles(theme => ({
  button: {
    marginRight: theme.spacing(1),
  },
  instructions: {
    marginTop: theme.spacing(1),
    marginBottom: theme.spacing(1),
  },
}));


export default function Step4Confirm(props) {
  const classes = useStyles()
  const [error, setError] = useState()

  const handleNext = () => {
    const data = {
      perso_nr: props.token,
      wahllokal_id: props.wahllokal,
      wahlkreis: props.wahlkreis,
      stimmkreis: +props.stimmkreis,
      e_kandidat: props.erststimme,
      z_kandidat: props.zweitstimme.kandidat,
      z_partei: props.zweitstimme.partei
    }


    fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL}/rpc/stimmabgabe`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
      })
      .then((res) => {
        if (res.status === 200) {
          props.setActiveStep((prevActiveStep) => prevActiveStep + 1);
        }
        return res.json()
      })
      .then((data) => setError(data));


  };
  const handleBack = () => {
    props.setActiveStep((prevActiveStep) => prevActiveStep - 1);
  };

  const getErststimme = () => {
    const kandidat = props.stimmzettelErststimme?.find((kandidat) => kandidat.nummer === props.erststimme);

    if (kandidat) {
      return `${kandidat.name} (${kandidat.partei})`
    } else {
      return 'Enthaltung'
    }
  }

  const getZweitstimme = () => {
    const kandidat = props.stimmzettelZweitstimme?.find((kandidat) => kandidat.persnr === props.zweitstimme.kandidat);
    if (kandidat && !props.zweitstimme.partei) {
      return `${kandidat.name} (${kandidat.partei})`
    } else if (!kandidat && props.zweitstimme.partei) {
      return `Liste der ${props.zweitstimme.partei} angenommen`
    } else {
      return 'Enthaltung'
    }
  }

  return <>
    { error && (<Alert severity="error">
      <AlertTitle>{error.hint}</AlertTitle>
      {error.details}
    </Alert>)}
    <div>
      <dl>
        <dd>Ihre Personalausweisnummer</dd>
        <dt>{props.token}</dt>
        <dd>Ihre Erststimme</dd>
        <dt>{getErststimme()}</dt>
        <dd>Ihre Zweitstimme</dd>
        <dt>{getZweitstimme()}</dt>
      </dl>
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
        Absenden
      </Button>
    </div>
  </>
}