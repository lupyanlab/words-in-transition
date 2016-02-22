from StringIO import StringIO
import requests
import pandas as pd


class Qualtrics:
    def __init__(self, user, token):
        self.root_url = 'https://survey.qualtrics.com/WRAPI/ControlPanel/api.php'
        self.base_params = dict(
            API_SELECT='ControlPanel',
            Version=2.5,
            User=user,
            Token=token,
        )

    def get_survey_id(self, name):
        """Get the survey id assigned by Qualtrics given the survey name."""
        response = self.get(Request='getSurveys', Format='JSON')
        surveys = response.json()['Result']['Surveys']
        for survey in surveys:
            if survey['SurveyName'] == name:
                return survey['SurveyID']
        raise AssertionError('survey {} not found'.format(name))

    def get_survey(self, name):
        """Get the body of the survey in JSON format."""
        survey_id = self.get_survey_id(name)
        response = self.get(Request='getSurvey', SurveyID=survey_id, Format='JSON')
        print response.url
        return response.content

    def get_survey_responses(self, name):
        """Get the survey data."""
        survey_id = self.get_survey_id(name)
        response = self.get(Request='getLegacyResponseData', Format='CSV',
                            SurveyID=survey_id)
        response_csv = StringIO(response.content)
        survey_data = pd.DataFrame.from_csv(response_csv)
        return survey_data

    def get(self, **kwargs):
        params = self.base_params.copy()
        params.update(kwargs)
        return requests.get(self.root_url, params=params)
